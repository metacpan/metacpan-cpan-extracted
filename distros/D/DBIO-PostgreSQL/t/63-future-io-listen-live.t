use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE LISTEN/NOTIFY over the future_io transport against a real PostgreSQL
# (karr k77; core ADR 0056, dbio-async ADR 0005). The offline half,
# t/62-future-io-listen.t, pins the seams against a fake DBD::Pg; this file
# pins what only a real server and a real libpq can show: that notifications
# arrive, in order, per channel; that pg_terminate_backend is noticed and
# healed with every channel LISTENed again; that a forked child's exit leaves
# the parent's LISTEN session alone; and that notify() goes out and comes
# back.
#
# The loop is set up the way a consumer sets it up: IO::Async::Loop->new, the
# magic singleton Future::IO::Impl::IOAsync binds to. Every wait is bounded.
#
# Gated like the other live tests: needs DBIO_TEST_PG_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io LISTEN test';
}

use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');
plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
  unless defined &DBIO::Async::Storage::_listen_drain;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

my $loop = IO::Async::Loop->new;

# Run the loop until $cond holds or $timeout passes. Never open-ended.
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

# Let the loop run for a while -- for "nothing more arrives" claims.
sub run_for {
  my ($seconds) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  $loop->loop_once(0.05) while Time::HiRes::time() < $deadline;
  return;
}

# The second connection that sends. AutoInactiveDestroy so the fork in d)
# cannot end it from the child.
my $sender = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });
sub send_notify {
  my ($channel, $payload) = @_;
  $sender->do('SELECT pg_notify(?, ?)', undef, $channel, $payload);
}

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io backend';

my (@errors, $reconnects);
$async->on_listen_error(sub { push @errors, $_[1] });
$async->on_listen_reconnect(sub { $reconnects++ });
$async->listen_backoff_initial(0.2);
$async->listen_backoff_max(1);

# Channels unique to this run: the database is shared.
my $A = "dbio_k77_${$}_a";
my $B = "dbio_k77_${$}_b";
my (@got_a, @got_b);

# The listen connection's backend pid. Reaching into core's state is a test's
# privilege; a consumer asks listen_alive.
sub listen_pid {
  my $conn = $async->{_listen} && $async->{_listen}{conn} or return undef;
  return $conn->{dbh} && $conn->{dbh}{pg_pid};
}

subtest 'a) LISTEN + 3 NOTIFYs from a second connection -> 3 callbacks, in order' => sub {
  my $f = $async->listen($A => sub { push @got_a, [@_] });
  $f->get;
  ok $f->is_done, 'listen resolved';
  ok $async->listen_alive, 'listen_alive';
  ok listen_pid(), 'on a dedicated listen connection';
  isnt listen_pid(), $sender->{pg_pid}, '... not the sender\'s';

  send_notify($A, "a$_") for 1 .. 3;
  ok wait_until(sub { @got_a >= 3 }), 'three notifications arrived';
  is_deeply \@got_a,
    [ map { [ $A, "a$_", $sender->{pg_pid} ] } 1 .. 3 ],
    '... in order, as ($channel, $payload, $sender_pid) with the sender\'s backend pid';
};

subtest 'b) two channels, each gets its own payloads' => sub {
  my $pid = listen_pid();
  $async->listen($B => sub { push @got_b, [@_] })->get;
  is listen_pid(), $pid, 'the second channel shares the listen connection';

  @got_a = ();
  send_notify($B, 'b1');
  send_notify($A, 'a4');
  send_notify($B, 'b2');
  ok wait_until(sub { @got_a >= 1 && @got_b >= 2 }), 'all three arrived';
  is_deeply [ map { $_->[1] } @got_a ], ['a4'], "channel $A got its own payload";
  is_deeply [ map { $_->[1] } @got_b ], [ 'b1', 'b2' ], "channel $B got its own, in order";
  is_deeply [ map { $_->[0] } @got_a, @got_b ], [ $A, $B, $B ], '... each named by its channel';
};

subtest 'c) pg_terminate_backend -> not alive -> self-healing -> alive -> NOTIFY on ALL channels' => sub {
  my $old_pid = listen_pid();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };   # libpq's FATAL notice

  my $ok = eval { $sender->selectrow_array('SELECT pg_terminate_backend(?)', undef, $old_pid) };
  plan skip_all => "cannot terminate the listen backend: " . ($@ || 'refused')
    unless $ok;

  ok wait_until(sub { @errors }), 'the dead connection was noticed (on_listen_error)';
  # libpq words the loss by how the connection was closed: over TLS a session
  # the server ends is "SSL connection has been closed unexpectedly" (karr k112).
  like join("\n", @errors),
    qr/server closed the connection|SSL connection has been closed|terminating connection|connection not open/i,
    '... with libpq\'s reason';
  ok !$async->listen_alive, 'listen_alive is false while the rebuild is pending';

  ok wait_until(sub { $reconnects }), 'on_listen_reconnect fired: the connection was rebuilt';
  ok $async->listen_alive, 'listen_alive is true again';
  my $new_pid = listen_pid();
  ok $new_pid && $new_pid != $old_pid, "on a new backend ($old_pid -> " . ($new_pid // 'none') . ')';

  @got_a = ();
  @got_b = ();
  send_notify($A, 'healed-a');
  send_notify($B, 'healed-b');
  ok wait_until(sub { @got_a && @got_b }), 'a NOTIFY after the rebuild arrives';
  is_deeply [ $got_a[0][1], $got_b[0][1] ], [ 'healed-a', 'healed-b' ],
    '... on BOTH channels -- every channel was LISTENed again';
  diag "warnings during the termination: @warnings" if @warnings && !Test::More->builder->is_passing;
};

subtest 'd) fork: a child that exits leaves the parent\'s LISTEN session alone' => sub {
  my $pid        = listen_pid();
  my $errors     = @errors;
  my $rebuilt    = $reconnects // 0;

  my $child = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    # The child touches nothing and exits normally: END blocks and global
    # destruction run, and with them DESTROY on its copies of every handle.
    exit 0;
  }
  waitpid($child, 0);
  is $? >> 8, 0, 'the child exited normally';

  @got_a = ();
  send_notify($A, 'after-fork');
  ok wait_until(sub { @got_a }), 'the parent still receives';
  is $got_a[0][1], 'after-fork', '... the notification sent after the child exited';
  is listen_pid(), $pid, '... on the SAME backend -- the child did not end the session';
  is $reconnects // 0, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errors, '... and without a listen error';
  ok $async->listen_alive, 'listen_alive';
};

subtest 'e) unlisten -> no further delivery' => sub {
  $async->unlisten($B)->get;
  ok $async->listen_alive, 'still listening on the other channel';

  @got_a = ();
  @got_b = ();
  send_notify($B, 'unheard');
  send_notify($A, 'heard');
  # One session's notifications arrive in the order they were sent: once the
  # second is here, the first would have been too.
  ok wait_until(sub { @got_a }), 'the still-listened channel delivers';
  run_for(0.2);
  is_deeply \@got_b, [], "nothing was delivered for the unlistened channel $B";
};

subtest 'f) notify() resolves, and the notification is delivered' => sub {
  @got_a = ();
  my $f = $async->notify($A => 'via-notify');
  ok wait_until(sub { $f->is_ready }), 'the notify Future resolved';
  ok $f->is_done, '... successfully';
  ok wait_until(sub { @got_a }), 'the listener received it';
  is $got_a[0][1], 'via-notify', '... with the payload';
  ok $got_a[0][2] != listen_pid() && $got_a[0][2] != $sender->{pg_pid},
    '... sent from a pooled connection -- neither the listen nor the sender backend';

  @got_a = ();
  $async->notify($A)->get;
  ok wait_until(sub { @got_a }), 'notify without a payload';
  is $got_a[0][1], '', '... arrives with the empty payload (PostgreSQL has no NULL payload)';
};

my $pid = listen_pid();
$async->unlisten($A)->get;
ok !defined listen_pid(), 'the last unlisten closed the listen connection';
my $gone = !$sender->selectrow_array(
  'SELECT 1 FROM pg_stat_activity WHERE pid = ?', undef, $pid);
ok $gone || wait_until(sub {
  !$sender->selectrow_array('SELECT 1 FROM pg_stat_activity WHERE pid = ?', undef, $pid)
}, 5), '... and its backend is gone';

$sender->disconnect;
done_testing;

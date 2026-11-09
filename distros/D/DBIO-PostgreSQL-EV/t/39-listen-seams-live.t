use strict;
use warnings;
use Test::More;
use File::Temp ();
use POSIX ();

# LIVE LISTEN/NOTIFY over the ev transport against a real PostgreSQL (karr
# k43; core ADR 0056). The offline half, t/38-listen-seams-mock.t, pins the
# seams against a fake EV::Pg; this file pins what only a real server, real
# libpq and a real fork can show: that notifications arrive, in order, per
# channel; that pg_terminate_backend is noticed and healed with every channel
# LISTENed again; that a forked child -- one that exits, one that resumes the
# EV loop -- leaves the parent's LISTEN session alone; that unlisten stops
# delivery; and that notify() goes out and comes back. Mirrors
# dbio-postgresql's t/63-future-io-listen-live.t for the future_io transport.
#
# Driven the way a consumer drives it: a schema connected with
# { async => 'ev' }, the public API on $schema->storage->async, the EV loop run
# by the Futures' get and by bounded waits. Reaching into core's listen state
# is kept to reading the listen backend's pid, a test's privilege.
#
# Before k43: nothing here healed (on_error only warned), a child that exited
# ended the parent's LISTEN session (measured in k45), and listen returned no
# Future to wait on.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use DBIO::Storage::Async ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

alarm 300;

# Run the EV loop until $cond holds or $timeout passes. Never open-ended.
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = EV::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# Let the loop run for a while -- for "nothing more arrives" claims.
sub run_for {
  my ($seconds) = @_;
  my $deadline = EV::time() + $seconds;
  wait_until(sub { EV::time() > $deadline }, $seconds + 1);
  return;
}

# get, bounded: a Future that does not settle fails the test instead of
# hanging it.
sub settle {
  my ($f, $what) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(15, 0, sub { $f->fail("watchdog: $what still pending after 15s\n") unless $f->is_ready });
  $dog->keepalive(0);
  return eval { $f->get; 1 } ? 1 : do { diag "$what: $@"; 0 };
}

my $h     = DBIO::PostgreSQL::EV::TestHarness->new;
my $async = $h->async;
isa_ok $async, 'DBIO::PostgreSQL::EV::Storage', 'the ev backend';

# The second connection that sends. AutoInactiveDestroy so the forks below
# cannot end it from a child. A server that is not there fails the file here
# (karr k77).
my $sender = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });
my $sender_pid = $sender->{pg_pid};
sub send_notify {
  my ($channel, $payload) = @_;
  $sender->do('SELECT pg_notify(?, ?)', undef, $channel, $payload);
}
sub backend_alive {
  my ($pid) = @_;
  return $sender->selectrow_array('SELECT count(*) FROM pg_stat_activity WHERE pid = ?', undef, $pid);
}

my (@errors, $reconnects);
$async->on_listen_error(sub { push @errors, $_[1] });
$async->on_listen_reconnect(sub { $reconnects++ });
$async->listen_backoff_initial(0.2);
$async->listen_backoff_max(1);

# Channels unique to this run: the database is shared.
my $A = "dbio_k43_${$}_a";
my $B = "dbio_k43_${$}_b";
my (@got_a, @got_b);

sub listen_pid {
  my $conn = $async->{_listen} && $async->{_listen}{conn} or return undef;
  return $conn->{pg} && $conn->{pg}->backend_pid;
}

subtest 'a) LISTEN + 3 NOTIFYs from a second connection -> 3 callbacks, in order' => sub {
  my $f = $async->listen($A => sub { push @got_a, [@_] });
  ok settle($f, 'listen'), 'listen resolved (get ran the EV loop)';
  ok $async->listen_alive, 'listen_alive';
  ok listen_pid(), 'on a dedicated listen connection';
  isnt listen_pid(), $sender_pid, '... not the sender\'s';

  send_notify($A, "a$_") for 1 .. 3;
  ok wait_until(sub { @got_a >= 3 }), 'three notifications arrived';
  is_deeply \@got_a,
    [ map { [ $A, "a$_", $sender_pid ] } 1 .. 3 ],
    '... in order, as ($channel, $payload, $sender_pid) with the sender\'s backend pid';
};

subtest 'b) two channels share the connection, each gets its own payloads' => sub {
  my $pid = listen_pid();
  ok settle($async->listen($B => sub { push @got_b, [@_] }), 'listen B'), 'the second listen resolved';
  is listen_pid(), $pid, 'the second channel shares the listen connection';

  @got_a = ();
  send_notify($B, 'b1');
  send_notify($A, 'a4');
  send_notify($B, 'b2');
  ok wait_until(sub { @got_a >= 1 && @got_b >= 2 }), 'all three arrived';
  is_deeply [ map { $_->[1] } @got_a ], ['a4'], 'channel A got its own payload';
  is_deeply [ map { $_->[1] } @got_b ], [ 'b1', 'b2' ], 'channel B got its own, in order';
};

subtest 'c) channel names: one identifier with a dot; over 63 bytes refused' => sub {
  my $dotted = "dbio_k43_$$.dotted";
  my @got;
  ok settle($async->listen($dotted => sub { push @got, [@_] }), 'listen dotted'),
    'listen on a dotted channel resolved';
  send_notify($dotted, 'dot');
  ok wait_until(sub { @got }), 'pg_notify on the same name reaches it -- LISTEN took it as ONE identifier';
  is_deeply $got[0], [ $dotted, 'dot', $sender_pid ], '... under its full name';
  ok settle($async->unlisten($dotted), 'unlisten dotted'), 'unlisten on it resolved';

  ok !eval { $sender->do('LISTEN "dbio_k43"."dotted"'); 1 },
    'control: the split form the SQLMaker quoting produced before k43 is not a LISTEN PostgreSQL accepts';

  my $pid  = listen_pid();
  my $long = $async->listen(('x' x 64) => sub { });
  ok wait_until(sub { $long->is_ready }) && $long->is_failed, 'listen on a 64-byte channel fails';
  like scalar $long->failure, qr/at most 63 bytes/, '... saying why';
  is listen_pid(), $pid, '... on the same listen connection -- it was not rebuilt';
  ok $async->listen_alive, '... and listening goes on';
  @errors = ();
};

subtest 'd) pg_terminate_backend -> not alive -> self-healing -> alive -> NOTIFY on ALL channels' => sub {
  my $old_pid = listen_pid();
  my $ok = eval { $sender->selectrow_array('SELECT pg_terminate_backend(?)', undef, $old_pid) };
  plan skip_all => 'cannot terminate the listen backend: ' . ($@ || 'refused')
    unless $ok;

  ok wait_until(sub { @errors }), 'the dead connection was noticed (on_listen_error)';
  like $errors[0], qr/the listen connection was lost: \S/,
    '... reported by EV::Pg\'s on_error, with libpq\'s reason';
  note "the error: $errors[0]";
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

  my $pid = listen_pid();
  ok settle($async->listen_reconnect, 'listen_reconnect'), 'listen_reconnect (a watchdog) resolved';
  is $reconnects, 2, '... and fired on_listen_reconnect';
  isnt listen_pid(), $pid, '... on yet another backend';
  ok wait_until(sub { !backend_alive($pid) }, 5), '... the replaced backend is gone';
  @got_a = ();
  send_notify($A, 'after-reconnect');
  ok wait_until(sub { @got_a }), '... and it delivers';
  @errors = ();
};

my $report = File::Temp->new;

sub run_child {
  my ($code) = @_;
  my $child = fork;
  die "fork: $!" unless defined $child;
  unless ($child) {
    alarm 20;
    $code->();
    exit 0;   # normal exit: END blocks and global destruction run
  }
  return $child;
}

subtest 'e) fork: a child that exits leaves the parent\'s LISTEN session alone' => sub {
  my $pid     = listen_pid();
  my $errors  = @errors;
  my $rebuilt = $reconnects;

  my $child = run_child(sub { });
  waitpid($child, 0);
  is $? >> 8, 0, 'the child exited normally, destroying its copies of every handle';

  @got_a = ();
  send_notify($A, 'after-fork');
  ok wait_until(sub { @got_a }), 'the parent still receives';
  is $got_a[0][1], 'after-fork', '... the notification sent after the child exited';
  is listen_pid(), $pid, '... on the SAME backend -- the child did not end the session';
  ok backend_alive($pid), '... which is alive';
  is $reconnects, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errors, '... and without a listen error';
  ok $async->listen_alive, 'listen_alive';
};

subtest 'f) fork: a child that resumes the EV loop does not read the parent\'s notifications' => sub {
  my $pid     = listen_pid();
  my $errors  = @errors;
  my $rebuilt = $reconnects;
  @got_a = ();

  my $child = run_child(sub {
    EV::now_update();
    my $stop = EV::timer(1.5, 0, sub { EV::break(EV::BREAK_ALL()) });
    EV::run();
    open my $fh, '>', $report->filename or POSIX::_exit(2);
    print {$fh} scalar(@got_a), "\n";
    close $fh;
    # Leave without destructors: this subtest is about the loop only; the
    # child's exit is subtest e).
    POSIX::_exit(0);
  });

  run_for(0.3);   # the child's loop is running
  send_notify($A, "while-child-$_") for 1 .. 3;
  ok wait_until(sub { @got_a >= 3 }), 'the parent received all three while the child ran its loop';
  is_deeply [ map { $_->[1] } @got_a ], [ map { "while-child-$_" } 1 .. 3 ], '... in order';

  waitpid($child, 0);
  is $? >> 8, 0, 'the child ran its loop and exited';
  open my $fh, '<', $report->filename or die "report: $!";
  chomp(my $seen = <$fh> // '');
  is $seen, 0, 'in the child no notification was dispatched';

  is listen_pid(), $pid, 'the parent is still on the SAME backend';
  is $reconnects, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errors, '... and without a listen error';
};

subtest 'g) unlisten -> no further delivery' => sub {
  ok settle($async->unlisten($B), 'unlisten B'), 'unlisten resolved';
  ok $async->listen_alive, 'still listening on the other channel';

  @got_a = ();
  @got_b = ();
  send_notify($B, 'unheard');
  send_notify($A, 'heard');
  # One session's notifications arrive in the order they were sent: once the
  # second is here, the first would have been too.
  ok wait_until(sub { @got_a }), 'the still-listened channel delivers';
  run_for(0.2);
  is_deeply \@got_b, [], 'nothing was delivered for the unlistened channel';
};

subtest 'h) notify() resolves, and the notification is delivered' => sub {
  @got_a = ();
  my $f = $async->notify($A => 'via-notify');
  ok settle($f, 'notify'), 'the notify Future resolved';
  ok wait_until(sub { @got_a }), 'the listener received it';
  is $got_a[0][1], 'via-notify', '... with the payload';
  ok $got_a[0][2] != listen_pid() && $got_a[0][2] != $sender_pid,
    '... sent from a pooled connection -- neither the listen nor the sender backend';

  @got_a = ();
  ok settle($async->notify($A), 'notify without payload'), 'notify without a payload resolved';
  ok wait_until(sub { @got_a }), '... and was delivered';
  is $got_a[0][1], '', '... with the empty payload (PostgreSQL has no NULL payload)';

  my $big = $async->notify($A => 'x' x 8000);
  ok wait_until(sub { $big->is_ready }) && $big->is_failed,
    'a payload of 8000 bytes fails the notify Future (the server\'s limit)';
  note 'the error: ' . ($big->failure // '');
  my $long = $async->notify(('x' x 64) => 'p');
  ok wait_until(sub { $long->is_ready }) && $long->is_failed,
    'a 64-byte channel fails the notify Future (pg_notify refuses it)';
  note 'the error: ' . ($long->failure // '');
};

my $pid = listen_pid();
ok settle($async->unlisten($A), 'unlisten A'), 'the last unlisten resolved';
ok !defined listen_pid(), '... and closed the listen connection';
ok wait_until(sub { !backend_alive($pid) }, 5), '... its backend is gone';
is_deeply \@errors, [], 'no listen errors since the healing test';

$h->disconnect;
$sender->disconnect;
done_testing;

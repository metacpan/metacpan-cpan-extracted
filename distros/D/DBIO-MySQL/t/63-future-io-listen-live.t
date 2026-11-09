use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use POSIX ();

# LIVE emulated LISTEN/NOTIFY over the future_io transport against a real
# MySQL / MariaDB server (karr k54; core ADR 0056, dbio-async ADR 0005, this
# dist's ADR 0008). The offline halves -- t/61-notify-table.t (the shared
# DBIO::MySQL::NotifyTable) and t/62-future-io-listen.t (the transport over a
# fake DBD) -- pin the logic against a model of the table; this file pins what
# only a real server and a real DBD can show: that the statements run on the
# server, that a notification from another session arrives on commit, that two
# real transactions committing out of id order are both delivered exactly once,
# that a KILLed listen connection is noticed and healed with every channel
# subscribed again, and that a forked child leaves the parent's pool and listen
# connections alone.
#
# Runs through whichever DBD the DSN names (dbi:mysql: -> DBD::mysql and
# DBIO::MySQL::Storage::Async, dbi:MariaDB: -> DBD::MariaDB and
# DBIO::MySQL::Storage::MariaDB::Async). The notify table is test-specific,
# created through deploy_notify_table and dropped at the end. The loop is set
# up the way a consumer sets it up: IO::Async::Loop->new, the magic singleton
# Future::IO::Impl::IOAsync binds to. Every wait is bounded.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
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

use DBI;
use DBIO::Test;
use DBIO::MySQL::NotifyTable;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');
plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
  unless defined &DBIO::Async::Storage::_listen_drain;

# A schema always declares its driver (core ADR 0067), and DBIO::Test::Schema
# keeps none in its class: declare the storage class the DSN's DBD is
# registered for -- DBIO::MySQL::Storage::MariaDB for a dbi:MariaDB: DSN.
my $test_schema = DBIO::Test::Schema->clone;
$test_schema->storage_type(
  $dsn =~ /\Adbi:MariaDB:/i ? '+DBIO::MySQL::Storage::MariaDB' : '+DBIO::MySQL::Storage'
);

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

sub run_for {
  my ($seconds) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  $loop->loop_once(0.05) while Time::HiRes::time() < $deadline;
  return;
}

# A notify table and channels unique to this run: the database is shared.
my $T  = "dbio_k54_notify_$$";
my $NT = DBIO::MySQL::NotifyTable->new(table => $T);
my $A  = "k54_${$}_a";
my $B  = "k54_${$}_b";
my $C  = "k54_${$}_c";

# Raw connections of other sessions. AutoInactiveDestroy so the forks in f)
# and g) cannot end them from the child.
sub raw {
  return DBI->connect($dsn, $user, $pass, {
    AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
  });
}
sub thread_id { my $dbh = shift; $dbh->{ lc($dbh->{Driver}{Name}) . '_thread_id' } }

my $sender = raw();
sub send_notify {
  my ($dbh, $channel, $payload) = @_;
  my ($sql, $bind) = $NT->notify_sql($channel, $payload);
  $dbh->do($sql, undef, @$bind);
  return $dbh->last_insert_id(undef, undef, undef, undef);
}

my $schema = $test_schema->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::MySQL::Storage::Async', 'the future_io backend';
my $drv = $dsn =~ /^dbi:MariaDB:/i ? 'MariaDB' : 'mysql';
isa_ok $async, 'DBIO::MySQL::Storage::MariaDB::Async', '... the MariaDB one for a dbi:MariaDB: DSN'
  if $drv eq 'MariaDB';

$async->notify_table($T);
$async->notify_poll_interval(0.1);
$async->listen_backoff_initial(0.2);
$async->listen_backoff_max(1);

my (@errors, $reconnects);
$async->on_listen_error(sub { push @errors, $_[1] });
$async->on_listen_reconnect(sub { $reconnects++ });

# The listen connection's server thread. Reaching into core's state is a test's
# privilege; a consumer asks listen_alive.
sub listen_dbh { my $c = $async->{_listen} && $async->{_listen}{conn}; $c && $c->{dbh} }
sub listen_tid { my $dbh = listen_dbh() or return undef; thread_id($dbh) }

$sender->do($NT->drop_table_sql);

# The database is shared: whatever happens below, the table goes -- from this
# process only, never from a child forked in f) or g).
my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    eval { raw()->do($NT->drop_table_sql) };
  }
}

# A listen before the table exists is refused with the way out named -- the
# emulation never creates its table behind the deployer's back.
subtest '0) no table: listen is refused, naming deploy_notify_table' => sub {
  my $f = $async->listen($A => sub {});
  ok wait_until(sub { $f->is_ready }), 'listen settled';
  like scalar $f->failure, qr/does not exist.*deploy_notify_table/s, '... failed, naming the way out';
  ok !$reconnects, '... without a reconnect loop';
  @errors = ();
};

$async->deploy_notify_table->get;
ok $sender->selectrow_array('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', undef, $T),
  "deploy_notify_table created $T";

my (@got_a, @got_b);

# The listen connection is forked-off-safe and never auto-reconnects: DBD::mysql
# turns mysql_auto_reconnect ON by itself under CGI/mod_perl, and a silently
# rebuilt session would hide the death core must see.
subtest 'a) LISTEN, NOTIFY from a second session -> delivered in order, with the sender' => sub {
  send_notify($sender, $A, 'history');
  {
    local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    my $f = $async->listen($A => sub { push @got_a, [@_] });
    $f->get;
    ok $f->is_done, 'listen resolved';
  }
  ok listen_tid(), 'on a dedicated listen connection';
  isnt listen_tid(), thread_id($sender), '... not the sender\'s';
  ok !listen_dbh()->{"${\ lc $drv}_auto_reconnect"},
    "... with ${\ lc $drv}_auto_reconnect off even under GATEWAY_INTERFACE";
  ok $async->listen_alive, 'listen_alive';

  send_notify($sender, $A, "a$_") for 1 .. 3;
  ok wait_until(sub { @got_a >= 3 }), 'three notifications arrived';
  run_for(0.3);
  is_deeply \@got_a, [ map { [ $A, "a$_", thread_id($sender) ] } 1 .. 3 ],
    '... in order, as ($channel, $payload, $sender_pid) with the sender\'s CONNECTION_ID(); '
  . 'the one sent before listen is history';
};

subtest 'b) two channels, each gets its own; channels are exact' => sub {
  my $tid = listen_tid();
  $async->listen($B => sub { push @got_b, [@_] })->get;
  is listen_tid(), $tid, 'the second channel shares the listen connection';

  @got_a = ();
  send_notify($sender, $B, 'b1');
  send_notify($sender, "$A ", 'trailing space');   # utf8mb4_bin pads in SQL
  send_notify($sender, uc $A, 'other case');
  send_notify($sender, $A, 'a4');
  send_notify($sender, $B, 'b2');
  ok wait_until(sub { @got_a >= 1 && @got_b >= 2 }), 'arrived';
  run_for(0.3);
  is_deeply [ map { $_->[1] } @got_a ], ['a4'], "channel $A got only its own -- not the padded or upper-case name";
  is_deeply [ map { $_->[1] } @got_b ], [ 'b1', 'b2' ], "channel $B got its own, in order";
};

# The pitfall the emulation exists to solve, on real InnoDB: AUTO_INCREMENT
# ids are handed out at INSERT, rows become visible at COMMIT.
subtest 'c) out-of-order commit: two transactions, the lower id commits last -> both, once each' => sub {
  my ($ta, $tb) = (raw(), raw());
  $ta->begin_work;
  my $id_a = send_notify($ta, $A, 'txn-A');
  $tb->begin_work;
  my $id_b = send_notify($tb, $A, 'txn-B');
  ok $id_a < $id_b, "A took the lower id ($id_a < $id_b)";

  @got_a = ();
  $tb->commit;
  ok wait_until(sub { @got_a }), 'B, committed first, is delivered';
  is $got_a[0][1], 'txn-B', '... it is B';
  run_for(0.3);
  $ta->commit;
  ok wait_until(sub { @got_a >= 2 }), 'A, the lower id committed later, is delivered too';
  run_for(0.5);
  is_deeply [ map { $_->[1] } @got_a ], [ 'txn-B', 'txn-A' ], 'each exactly once';

  # In flight at LISTEN time: INSERTed before the channel was listened on,
  # committed after -- delivered on commit, as PostgreSQL does.
  my @got_c;
  $ta->begin_work;
  send_notify($ta, $C, 'open-at-listen');
  send_notify($sender, $C, 'committed-before');
  $async->listen($C => sub { push @got_c, [@_] })->get;
  $ta->commit;
  ok wait_until(sub { @got_c }), 'a notification open at listen time is delivered when it commits';
  run_for(0.3);
  is_deeply [ map { $_->[1] } @got_c ], ['open-at-listen'], '... and the one committed before is history';
  $async->unlisten($C)->get;
  $_->disconnect for $ta, $tb;
};

subtest 'd) KILL the listen connection -> noticed -> rebuilt -> every channel delivers' => sub {
  my $old = listen_tid();
  ok $old, 'listening';
  @errors = ();
  $sender->do('KILL ' . int $old);

  ok wait_until(sub { $reconnects }), 'on_listen_reconnect fired: the connection was rebuilt';
  like join("\n", @errors), qr/Lost connection|gone away|server has gone|Killed|Server shutdown|interrupted/i,
    'on_listen_error heard why';
  ok $async->listen_alive, 'listen_alive is true again';
  my $new = listen_tid();
  ok $new && $new != $old, "on a new connection ($old -> " . ($new // 'none') . ')';

  @got_a = ();
  @got_b = ();
  send_notify($sender, $A, 'healed-a');
  send_notify($sender, $B, 'healed-b');
  ok wait_until(sub { @got_a && @got_b }), 'a NOTIFY after the rebuild arrives';
  is_deeply [ $got_a[0][1], $got_b[0][1] ], [ 'healed-a', 'healed-b' ],
    '... on BOTH channels -- every channel was subscribed again';
};

subtest 'e) notify() resolves, and the notification is delivered' => sub {
  @got_a = ();
  my $f = $async->notify($A => 'via-notify');
  ok wait_until(sub { $f->is_ready }), 'the notify Future resolved';
  ok $f->is_done, '... successfully';
  ok wait_until(sub { @got_a }), 'the listener received it';
  is $got_a[0][1], 'via-notify', '... with the payload';
  ok $got_a[0][2] != listen_tid() && $got_a[0][2] != thread_id($sender),
    '... sent from a pooled connection -- neither the listen nor the sender session';

  @got_a = ();
  $async->notify($A)->get;
  ok wait_until(sub { @got_a }), 'notify without a payload';
  is $got_a[0][1], '', '... arrives with the empty payload';
};

# Fork. A forked child holds a copy of every handle of the parent: the pool's,
# the listen connection's, $sender's. Whatever the child does with them, the
# parent's sessions must survive -- checked through the pool itself, with
# $async->notify after the child is gone, and through the listen connection.
# Core's half: neither the pool nor the listen state is torn down outside the
# pid that opened it (DBIO::Storage::PoolBase, core ADR 0056). This transport's
# half: every handle is opened with AutoInactiveDestroy (the pool's since karr
# k55), so the child's DESTROY of its copy does not end the parent's session.
# Without it, a DBD::mysql child that merely exits ends the parent's pooled
# sessions: "Lost connection to server during query" on the next notify.

# notify through the pool, and the pooled session it went out on -- the
# $sender_pid the listener receives is that session's CONNECTION_ID(). undef
# when it failed or was not delivered.
sub pooled_notify {
  my ($payload) = @_;
  @got_a = ();
  my $f = $async->notify($A => $payload);
  wait_until(sub { $f->is_ready }) && $f->is_done or return undef;
  wait_until(sub { @got_a }) or return undef;
  return $got_a[0][2];
}

# The usual "disconnect after fork": the child drops its inherited pool (and
# listen state) to get connections of its own, which DESTROYs its copies of the
# pool handles. It leaves with POSIX::_exit, so DBI's END does not run -- this
# is the DESTROY path alone, the one AutoInactiveDestroy governs on both DBDs.
subtest 'f) fork: a child that disconnects its inherited storage leaves the parent\'s pool and listen sessions alone' => sub {
  my $pooled  = pooled_notify('before-fork');
  ok $pooled, 'a notify through the pool before the fork';
  my $held    = $async->pool->acquire->get;   # a pool connection that lives across the fork
  my $held_id = held_session($held);
  my $tid     = listen_tid();
  my $errors  = @errors;
  my $rebuilt = $reconnects // 0;

  my $child = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    $async->disconnect;
    POSIX::_exit(0);
  }
  waitpid($child, 0);
  is $? >> 8, 0, 'the child disconnected its storage and exited';

  @got_a = ();
  my $f = $async->notify($A => 'after-fork');
  ok wait_until(sub { $f->is_ready }), 'a notify in the parent settled';
  ok $f->is_done, '... successfully: the pool connection the child dropped still works'
    or diag 'notify failed: ' . ($f->failure // 'cancelled');
  ok wait_until(sub { @got_a }), 'the listener received it';
  ok $got_a[0][2] && $got_a[0][2] != listen_tid(), '... sent from a pooled session, not the listen one';
  is held_session($held), $held_id,
    '... and the pool connection held across the fork is the SAME session and still answers';
  $async->pool->release($held);
  is listen_tid(), $tid, 'the listen connection is the SAME one';
  is $reconnects // 0, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errors, '... and without a listen error';
};

# The session id of a pool connection the test holds (the pool retires a
# connection at the end of every borrow, core ADR 0079, so "the same session"
# is asked of one that is held, not of the one the next notify gets).
sub held_session {
  my ($conn) = @_;
  return scalar $conn->{dbh}->selectrow_array('SELECT CONNECTION_ID()');
}

# The child simply exits: END blocks and global destruction run, DESTROY on
# its copies of every handle, and DBI's END runs disconnect_all. DBD::mysql's
# disconnect_all does nothing. DBD::MariaDB 1.24's walks every connection that
# DBD still lists and closes it -- or dies there in a DBI "active kids" panic,
# which turns the child's exit status into 22. That is the DBD's; the transport
# installs DBIO::MySQL::MariaDBForkGuard on its first connect, which makes the
# call a no-op in the child (karr k56, ADR 0009). No TODO: both DBDs pass.
subtest 'g) fork: a child that exits leaves the parent\'s pool and listen sessions alone' => sub {
  my $pooled  = pooled_notify('before-fork');
  ok $pooled, 'a notify through the pool before the fork';
  my $held    = $async->pool->acquire->get;   # a pool connection that lives across the fork
  my $held_id = held_session($held);
  my $tid     = listen_tid();
  my $errors  = @errors;
  my $rebuilt = $reconnects // 0;

  my $child = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    # The child touches nothing and exits normally.
    exit 0;
  }
  waitpid($child, 0);
  my $status = $? >> 8;

  run_for(1);
  @got_a = ();
  my $f = $async->notify($A => 'after-fork');
  ok wait_until(sub { $f->is_ready }), 'a notify in the parent settled';

  is $status, 0, 'the child exited normally';
  ok $f->is_done, '... and the notify succeeded: the pool connection the child inherited still works'
    or diag 'notify failed: ' . ($f->failure // 'cancelled');
  ok wait_until(sub { @got_a }, 3), 'the listener received it';
  ok $got_a[0][2] && $got_a[0][2] != listen_tid(), '... sent from a pooled session, not the listen one';
  is held_session($held), $held_id,
    '... and the pool connection held across the fork is the SAME session and still answers';
  $async->pool->release($held);
  is listen_tid(), $tid, 'the listen connection is the SAME one';
  is $reconnects // 0, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errors, '... and without a listen error';

  # Listening survives the child on either DBD.
  $sender = raw() unless $sender->ping;
  @got_a = ();
  send_notify($sender, $A, 'healed');
  ok wait_until(sub { @got_a }), 'listening survives the child';
  is $got_a[0][1], 'healed', '... the notification sent after it';
  ok $async->listen_alive, 'listen_alive';
};

subtest 'h) unlisten -> no further delivery' => sub {
  $async->unlisten($B)->get;
  ok $async->listen_alive, 'still listening on the other channel';
  @got_a = ();
  @got_b = ();
  send_notify($sender, $B, 'unheard');
  send_notify($sender, $A, 'heard');
  ok wait_until(sub { @got_a }), 'the still-listened channel delivers';
  run_for(0.3);
  is_deeply \@got_b, [], "nothing was delivered for the unlistened channel $B";
};

my $tid = listen_tid();
$async->unlisten($A)->get;
ok !defined listen_tid(), 'the last unlisten closed the listen connection';
ok wait_until(sub {
  !$sender->selectrow_array('SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid)
}, 5), '... and its server thread is gone';

$sender->do($NT->drop_table_sql);
$sender->disconnect;
done_testing;

use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use POSIX ();

# LIVE emulated LISTEN/NOTIFY over the ev transport against a real MySQL /
# MariaDB server (karr k44; core ADR 0056, dbio-mysql ADR 0008, this dist's ADR
# 0010). The offline half -- t/22-listen-notify-mock.t -- pins the logic
# against a fake EV::MariaDB and a model of the table; this file pins what only
# a real server and the real client library can show: that the statements run
# on the server, that a notification from another session arrives on commit,
# that two real transactions committing out of id order are both delivered
# exactly once, that a KILLed listen connection is noticed -- by a failed poll
# and, idle, by the socket probe -- and healed with every channel subscribed
# again, and that a forked child leaves the parent's listen session alone,
# whether it just exits or resumes the EV loop.
#
# Every wait is bounded. The notify table and the channels are unique to this
# run (the database is shared); the table is created through
# deploy_notify_table and dropped at the end, from this process only.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use DBI;
use DBIO::Util ();
use EV;
use DBIO::MySQL::NotifyTable;
use DBIO::MySQL::EV::Storage;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

my $h     = DBIO::MySQL::EV::TestHarness->new(connect_attrs => { pool_size => 2 });
my $async = $h->async;
isa_ok $async, 'DBIO::MySQL::EV::Storage', 'the ev backend';

my ($dsn, $user, $pass) = @{$h}{qw( dsn user pass )};

my $TICK = EV::timer(0.02, 0.02, sub {});   # RUN_ONCE never blocks for long

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

sub run_for {
  my $deadline = Time::HiRes::time() + $_[0];
  EV::run(EV::RUN_ONCE()) while Time::HiRes::time() < $deadline;
  return;
}

sub settled { my ($f, $t) = @_; wait_until(sub { $f->is_ready }, $t) or die "timed out awaiting a Future\n"; $f }

# A notify table and channels unique to this run: the database is shared.
my $T  = "dbio_k44_notify_$$";
my $NT = DBIO::MySQL::NotifyTable->new(table => $T);
my $A  = "k44_${$}_a";
my $B  = "k44_${$}_b";
my $C  = "k44_${$}_c";

# Raw DBI connections of other sessions, through whichever DBD the DSN names.
sub raw {
  # DBI dies quoting the DSN: named without a password it may carry (karr k76).
  my $dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
    });
  } or die DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
  return $dbh;
}
sub thread_id { my ($dbh) = @_; scalar $dbh->selectrow_array('SELECT CONNECTION_ID()') }
sub processlist_state {
  my ($dbh, $tid) = @_;
  return scalar $dbh->selectrow_array(
    'SELECT COALESCE(STATE, \'\') FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid);
}

my $sender = raw();
sub send_notify {
  my ($dbh, $channel, $payload) = @_;
  my ($sql, $bind) = $NT->notify_sql($channel, $payload);
  $dbh->do($sql, undef, @$bind);
  return $dbh->last_insert_id(undef, undef, undef, undef);
}

$async->notify_table($T);
$async->notify_poll_interval(0.1);
$async->listen_backoff_initial(0.2);
$async->listen_backoff_max(1);

my (@errors, $reconnects);
$async->on_listen_error(sub { push @errors, $_[1] });
$async->on_listen_reconnect(sub { $reconnects++ });

# The listen connection. Reaching into core's state is a test's privilege; a
# consumer asks listen_alive.
sub listen_conn { $async->{_listen} && $async->{_listen}{conn} }
sub listen_tid  { my $c = listen_conn() or return undef; $c->{mdb} ? $c->{mdb}->thread_id : undef }

$sender->do($NT->drop_table_sql);
my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    eval { raw()->do($NT->drop_table_sql) };
  }
}

# The emulation never creates its table behind the deployer's back: a listen
# before the table exists is refused on a live connection, naming the way out,
# and core does not reconnect in a loop over it.
subtest '0) no table: listen is refused, naming deploy_notify_table' => sub {
  my $f = settled($async->listen($A => sub {}));
  like scalar $f->failure, qr/`\Q$T\E` does not exist.*deploy_notify_table/s, 'listen failed, naming table and way out';
  run_for(0.5);
  ok !$reconnects, '... without a reconnect loop';
  ok !listen_conn(), '... and the connection is closed again';
  @errors = ();
};

settled($async->deploy_notify_table)->get;
ok $sender->selectrow_array(
  'SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', undef, $T),
  "deploy_notify_table created $T";

my (@got_a, @got_b);

# Contract order against a real server: listen's Future resolves after the mark
# was taken, so a notification sent right after it resolved is delivered and
# one committed before is history. The sender is the notifying session.
subtest 'a) listen -> notify from a second session: delivered in order, with the sender, no history' => sub {
  send_notify($sender, $A, 'history');
  my $f = $async->listen($A => sub { push @got_a, [@_] });
  ok !$f->is_ready, 'listen is pending on return';
  settled($f);
  ok $f->is_done, 'listen resolved';
  ok listen_tid(), 'on a dedicated listen connection';
  isnt listen_tid(), thread_id($sender), '... not the sender\'s';
  ok !(grep { $_->thread_id == listen_tid() } @{ $async->pool->{_connections} }),
    '... and not a pool connection';
  ok $async->listen_alive, 'listen_alive';

  send_notify($sender, $A, "a$_") for 1 .. 3;
  ok wait_until(sub { @got_a >= 3 }), 'three notifications arrived';
  run_for(0.3);
  is_deeply \@got_a, [ map { [ $A, "a$_", thread_id($sender) ] } 1 .. 3 ],
    '... in order, as ($channel, $payload, $sender_pid) with the sender\'s CONNECTION_ID(); '
  . 'the one sent before listen is history';
};

subtest 'b) two channels share the connection, each gets its own; channels are exact' => sub {
  my $tid = listen_tid();
  settled($async->listen($B => sub { push @got_b, [@_] }));
  is listen_tid(), $tid, 'the second channel shares the listen connection';

  @got_a = ();
  send_notify($sender, $B, 'b1');
  send_notify($sender, "$A ", 'trailing space');   # utf8mb4_bin pads in SQL
  send_notify($sender, uc $A, 'other case');
  send_notify($sender, $A, 'a4');
  send_notify($sender, $B, 'b2');
  ok wait_until(sub { @got_a >= 1 && @got_b >= 2 }), 'arrived';
  run_for(0.3);
  is_deeply [ map { $_->[1] } @got_a ], ['a4'], "$A got only its own -- not the padded or upper-case name";
  is_deeply [ map { $_->[1] } @got_b ], [ 'b1', 'b2' ], "$B got its own, in order";
};

# The pitfall the emulation exists for, on real InnoDB: AUTO_INCREMENT ids are
# handed out at INSERT, rows become visible at COMMIT.
subtest 'c) out-of-order commit: the lower id commits last -> both delivered, once each' => sub {
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

  # Open at LISTEN time: INSERTed before the channel was listened on,
  # committed after -- delivered on commit, as PostgreSQL does.
  my @got_c;
  $ta->begin_work;
  send_notify($ta, $C, 'open-at-listen');
  send_notify($sender, $C, 'committed-before');
  settled($async->listen($C => sub { push @got_c, [@_] }));
  $ta->commit;
  ok wait_until(sub { @got_c }), 'a notification open at listen time is delivered when it commits';
  run_for(0.3);
  is_deeply [ map { $_->[1] } @got_c ], ['open-at-listen'], '... the one committed before is history';
  settled($async->unlisten($C));
  $_->disconnect for $ta, $tb;
};

subtest 'd) KILL the listen connection -> the poll notices -> rebuilt -> every channel delivers' => sub {
  my $old = listen_tid();
  ok $old, 'listening';
  @errors = ();
  my $was = $reconnects // 0;
  $sender->do('KILL ' . int $old);

  ok wait_until(sub { ($reconnects // 0) > $was }), 'on_listen_reconnect fired: the connection was rebuilt';
  like join("\n", @errors), qr/failed: .*(?:Lost connection|gone away|Server has gone|Killed|interrupted)/i,
    'on_listen_error heard why';
  ok $async->listen_alive, 'listen_alive is true again';
  my $new = listen_tid();
  ok $new && $new != $old, "on a new connection ($old -> " . ($new // 'none') . ')';

  @got_a = ();
  @got_b = ();
  send_notify($sender, $A, 'healed-a');
  send_notify($sender, $B, 'healed-b');
  ok wait_until(sub { @got_a && @got_b }), 'a notification after the rebuild arrives';
  is_deeply [ $got_a[0][1], $got_b[0][1] ], [ 'healed-a', 'healed-b' ],
    '... on BOTH channels -- every channel was subscribed again';
};

# The probe, against a real server: EV::MariaDB's is_connected stays true after
# a KILL, and a ping would have to run the loop from inside listen_alive. The
# probe reads the idle socket instead -- the server's hang-up makes it
# readable. With a poll interval long enough that no poll finds the death
# first, listen_alive alone must see it.
subtest 'e) KILL an idle listen connection -> listen_alive says false -> healed' => sub {
  $async->notify_poll_interval(30);
  settled($async->listen_reconnect);
  my $old  = listen_tid();
  my $conn = listen_conn();
  ok $async->listen_alive, 'alive before';
  my $was = $reconnects // 0;
  $sender->do('KILL ' . int $old);
  run_for(0.3);   # the server's FIN arrives; no poll is due for 30 s
  ok $conn->{mdb}->is_connected, 'EV::MariaDB still calls the killed connection connected';
  ok !$async->listen_alive, 'listen_alive: false -- the probe saw the hang-up without a poll';
  ok wait_until(sub { ($reconnects // 0) > $was }), '... and healing rebuilt the connection';
  isnt listen_tid(), $old, '... on a new connection';

  $async->notify_poll_interval(0.1);
  settled($async->listen_reconnect);
  ok $async->listen_alive, 'back to a 0.1 s poll, alive';
  @errors = ();
};

subtest 'f) notify() resolves on a pooled connection, and the notification is delivered' => sub {
  @got_a = ();
  my $f = settled($async->notify($A => 'via-notify'));
  ok $f->is_done, 'the notify Future resolved';
  ok wait_until(sub { @got_a }), 'the listener received it';
  is $got_a[0][1], 'via-notify', '... with the payload';
  my %pooled = map { ($_->thread_id => 1) } @{ $async->pool->{_connections} };
  ok $pooled{ $got_a[0][2] }, '... sent from a pooled connection';

  @got_a = ();
  settled($async->notify($A));
  ok wait_until(sub { @got_a }), 'notify without a payload';
  is $got_a[0][1], '', '... arrives with the empty payload';
};

# A child that just exits: END blocks and global destruction run, and with them
# DESTROY on its copy of every EV::MariaDB handle. EV::MariaDB closes nothing in
# a forked process, so the parent's listen session must be the same one after.
# (The DBI handles are another matter: DBD::MariaDB ends every inherited
# connection at the child's exit -- dbio-mysql ADR 0008 -- so $sender is made
# anew below; that is not the listen connection's business.)
subtest 'g) fork: a child that exits leaves the parent\'s listen connection alone' => sub {
  my $tid     = listen_tid();
  my $errs    = @errors;
  my $rebuilt = $reconnects // 0;

  my $child = fork;
  die "fork: $!" unless defined $child;
  exit 0 unless $child;
  waitpid($child, 0);
  is $? >> 8, 0, 'the child exited normally';

  run_for(0.5);
  my $post = raw();
  @got_a = ();
  send_notify($post, $A, 'after-exit');
  ok wait_until(sub { @got_a }), 'the parent still receives';
  is $got_a[0][1], 'after-exit', '... the notification sent after the child exited';
  is listen_tid(), $tid, '... on the SAME connection';
  is $reconnects // 0, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errs, '... and without a listen error';
  ok $async->listen_alive, 'listen_alive';
  $post->disconnect;
  $sender = raw();
};

# A child that RESUMES the EV loop while a poll is in flight shares the
# parent's socket: unguarded, its copy of the handle would read the reply
# meant for the parent (measured, ADR 0010). LOCK TABLES from another session
# holds the poll on the server while the child forks and loops; the lock is
# released while the child's loop still runs.
subtest 'h) fork: a child that resumes the loop during a poll leaves the parent alone' => sub {
  my $tid     = listen_tid();
  my $errs    = @errors;
  my $rebuilt = $reconnects // 0;

  my $locker = raw();
  $locker->do("LOCK TABLES `$T` WRITE");
  ok wait_until(sub { listen_conn()->{busy} && processlist_state($sender, $tid) =~ /lock/i }, 5),
    'a poll is in flight on the listen connection, waiting for the lock';

  my $child = fork;
  die "fork: $!" unless defined $child;
  unless ($child) {
    my $stop = EV::timer(1.5, 0, sub { EV::break(EV::BREAK_ALL()) });
    EV::run();
    POSIX::_exit(0);   # no END: the parent's DBI sessions stay theirs
  }
  # The parent runs the loop while the child exits, and libev's default loop
  # reaps children itself: its child watcher, not waitpid, gets the status.
  my $status;
  my $reaper = EV::child($child, 0, sub { $status = $_[0]->rstatus });

  run_for(0.4);        # the child's loop is running
  $locker->do('UNLOCK TABLES');
  ok wait_until(sub { !listen_conn()->{busy} }, 5), 'the poll in flight completed in the parent';
  run_for(1.5);        # polls go on while the child still loops
  ok wait_until(sub { defined $status }, 5), 'the child looped and exited';
  is $status >> 8, 0, '... normally';

  @got_a = ();
  send_notify($sender, $A, 'after-loop-child');
  ok wait_until(sub { @got_a }), 'the parent still receives';
  is $got_a[0][1], 'after-loop-child', '... the notification sent afterwards';
  is listen_tid(), $tid, '... on the SAME connection';
  is $reconnects // 0, $rebuilt, '... without a rebuild';
  is scalar(@errors), $errs, '... and without a listen error'
    or diag explain [ @errors[ $errs .. $#errors ] ];
  $locker->disconnect;
};

subtest 'i) unlisten -> no further delivery' => sub {
  settled($async->unlisten($B));
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
settled($async->unlisten($A));
ok !defined listen_tid(), 'the last unlisten closed the listen connection';
ok wait_until(sub {
  !$sender->selectrow_array('SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid)
}, 5), '... and its server thread is gone';

$sender->do($NT->drop_table_sql);
$sender->disconnect;
done_testing;

use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use POSIX ();
use File::Temp ();
use Scalar::Util ();

# LIVE regression for karr k46: a forked child that resumes the EV loop leaves
# the parent's POOLED sessions alone (ADR 0010, amendment k46; the listen
# connection's case is t/22-listen-notify-live.t, subtest h).
#
# The bug it pins: EV::MariaDB's I/O callback does not check the pid, and EV
# re-arms the default loop in a child. A child that runs the loop while a
# pooled statement was in flight at fork time reads the reply off the socket it
# shares with the parent; the parent's statement never completes, and neither
# does anything after it on that session. The offline half,
# t/24-pool-fork-guard-mock.t, pins what the child does; only a real server
# and the real client can show the parent's side.
#
# Shape of each case: LOCK TABLES from a second session holds a pooled
# statement on the server; fork; the child runs the loop; the lock is released
# while the parent keeps OUT of the loop for a moment, so the child's loop meets
# the reply first -- the worst case. Then the parent must get its own reply and
# the pool must go on working on the same sessions. Covered for a statement on
# a connection checked out from the pool and on one pinned by txn_do_async.
#
# Case c) is the child that USES the pool (karr k56, the live half of karr k54;
# offline: claim 8 of t/24-pool-fork-guard-mock.t). With core karr k233 its
# first acquire takes the pool over: the parent's connections are dropped from
# the pool and the child opens one of its own. When that acquire comes before
# the child's loop has run, the pool's fork watcher finds the pool holding the
# child's connection, which it must leave working -- and the parent's two
# handles nowhere in the pool, though the statements in flight keep them alive
# with their watchers on the parent's sockets. Those it must finish all the
# same, or the child's loop, which that very acquire makes it run, reads the
# parent's replies. Both of the parent's connections are busy at fork time, one
# checked out and one pinned, so one case shows both.
#
# Every wait is bounded, so a hang fails instead of wedging the run: the loops
# by a deadline, every DBI session by a lock_wait_timeout, the file and the
# child of case c) by an alarm. The table is unique to this run and dropped at
# the end, from this process only, after its own sessions were ended; a child
# leaves through POSIX::_exit and runs no END block.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use DBI;
use DBIO::Util ();
use EV;

$SIG{ALRM} = sub { BAIL_OUT('t/24-pool-fork-live.t: alarm, a wait did not end') };
alarm 120;

my $h    = DBIO::MySQL::EV::TestHarness->new(connect_attrs => { pool_size => 2 });
my $async = $h->async;
my $pool  = $h->pool;
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

# A DBI session beside the pool. No statement of it waits for a lock without
# an end, and END ends those still open: one of them may hold the table's lock.
my @RAW;
sub raw {
  # DBI dies quoting the DSN: named without a password it may carry (karr k76).
  my $dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
    });
  } or die DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
  $dbh->do('SET SESSION lock_wait_timeout = 20');
  push @RAW, $dbh;
  Scalar::Util::weaken($RAW[-1]);
  return $dbh;
}

sub processlist_state {
  my ($dbh, $tid) = @_;
  return scalar $dbh->selectrow_array(
    'SELECT COALESCE(STATE, \'\') FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid) // '';
}

# The pooled connections that are not idle: those a statement is running on.
# A connection whose session is being reset (karr k100, core k398) is out of the
# pool's hands too, but no statement runs on it.
sub out_conns {
  my %idle = map { ($_ => 1) } @{ $pool->{_idle} };
  return grep { !$idle{$_} && !$pool->_connection_is_resetting($_) } @{ $pool->{_connections} };
}

# Run $dispatch; return its Future and the one connection it took out of the
# pool. Connections out before -- wedged by an earlier case of a red run --
# do not count, so each case stands on its own.
sub dispatch_on_one {
  my ($dispatch) = @_;
  # Sessions still being reset (karr k100, core k398) are not yet to be had.
  wait_until(sub { !%{ $pool->{_resetting} || {} } }, 5);
  my %before = map { ($_ => 1) } out_conns();
  my $f   = $dispatch->();
  my @new = grep { !$before{$_} } out_conns();
  return ($f, @new == 1 ? $new[0] : undef);
}

my $T     = "dbio_k46_fork_$$";
my $admin = raw();
$admin->do("DROP TABLE IF EXISTS `$T`");
$admin->do("CREATE TABLE `$T` (id INT PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
$admin->do("INSERT INTO `$T` (id, v) VALUES (1, 100)");

$h->warm_pool;
my @TIDS = sort { $a <=> $b } map { $_->thread_id } @{ $pool->{_connections} };
is scalar(@TIDS), 2, 'two pooled sessions';

# A red run leaves a session wedged, a transaction perhaps open on it: end
# those sessions before the DROP can wait for their locks.
my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    eval { $_->disconnect } for grep { defined } @RAW;
    eval {
      my $dbh = raw();
      $dbh->do('SET SESSION lock_wait_timeout = 10');
      eval { $dbh->do("KILL $_") } for @TIDS;
      $dbh->do("DROP TABLE IF EXISTS `$T`");
      $dbh->disconnect;
    };
  }
}

# Fork a child that runs the loop for a while, then writes what it saw.
sub fork_looping_child {
  my ($report) = @_;
  my $file  = File::Temp->new;
  my $child = fork;
  die "fork: $!" unless defined $child;
  unless ($child) {
    my $stop = EV::timer(1.5, 0, sub { EV::break(EV::BREAK_ALL()) });
    EV::run();
    if (open my $fh, '>', $file->filename) {
      print {$fh} join("\t", $report->()), "\n";
      close $fh;
    }
    POSIX::_exit(0);   # no END: the parent's sessions and table stay its own
  }
  # libev's default loop reaps children itself: its child watcher, not
  # waitpid, gets the status.
  my %c = (file => $file);
  $c{reaper} = EV::child($child, 0, sub { $c{status} = $_[0]->rstatus });
  return \%c;
}

sub child_report {
  my ($c) = @_;
  ok wait_until(sub { defined $c->{status} }, 5), 'the child looped and exited';
  is(($c->{status} // -1) >> 8, 0, '... normally');
  open my $fh, '<', $c->{file}->filename or return ();
  chomp(my $line = <$fh> // '');
  return split /\t/, $line;
}

# The lock is released while the parent stays out of the loop: the child's
# loop, running all the while, meets the reply first.
sub release_lock_to_the_child {
  my ($locker) = @_;
  Time::HiRes::sleep(0.3);       # the child's loop is running
  $locker->do('UNLOCK TABLES');
  Time::HiRes::sleep(0.5);
  return;
}

sub pool_still_serves {
  my @f = map { $async->_query_async('SELECT CONNECTION_ID(), ?', [ $_ ]) } 1 .. 2;
  ok wait_until(sub { !grep { !$_->is_ready } @f }, 5), 'the parent\'s next pooled queries complete';
  my @rows = map { $_->is_done ? ($_->get)[0] : [] } @f;
  is_deeply [ map { $_->[1] } @rows ], [ 1, 2 ], '... each with its own result';
  is_deeply [ sort { $a <=> $b } map { $_->[0] // 0 } @rows ], \@TIDS,
    '... on the same two sessions, none rebuilt';
}

subtest 'a) a pooled query in flight at fork time: the parent gets its own reply' => sub {
  my $locker = raw();
  $locker->do("LOCK TABLES `$T` WRITE");

  my ($f, $conn) = dispatch_on_one(sub {
    $async->_query_async("SELECT id, v FROM `$T` WHERE id = ?", [ 1 ]);
  });
  ok $conn, 'the query runs on a connection checked out from the pool';
  my $tid = $conn ? $conn->thread_id : 0;
  ok wait_until(sub { processlist_state($admin, $tid) =~ /lock/i }, 5),
    '... and waits for the lock on the server';

  my $c = fork_looping_child(sub { ($f->is_ready ? 1 : 0, $pool->available) });
  release_lock_to_the_child($locker);

  ok wait_until(sub { $f->is_ready }, 5), 'the query in flight at fork time completes in the parent';
  ok $f->is_done, '... successfully'
    or diag($f->is_failed ? $f->failure : "still pending");
  is_deeply [ $f->is_done ? $f->get : () ], [ [ 1, 100 ] ], '... with its own rows';

  my @r = child_report($c);
  is "@r", '0 1', 'in the child the query stayed pending and nothing was released';

  pool_still_serves();
  $locker->disconnect;
};

subtest 'b) a transaction\'s pinned connection with a statement in flight at fork time' => sub {
  my $locker = raw();
  $locker->do("LOCK TABLES `$T` WRITE");

  my ($txn, $conn) = dispatch_on_one(sub {
    $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("UPDATE `$T` SET v = v + 1 WHERE id = ?", [ 1 ]);
    });
  });
  ok $conn, 'the transaction pins a pooled connection';
  my $tid = $conn ? $conn->thread_id : 0;
  ok wait_until(sub { processlist_state($admin, $tid) =~ /lock/i }, 5),
    '... and its statement waits for the lock on the server';

  my $c = fork_looping_child(sub { ($txn->is_ready ? 1 : 0, $pool->available) });
  release_lock_to_the_child($locker);

  ok wait_until(sub { $txn->is_ready }, 5), 'the transaction in flight at fork time completes in the parent';
  ok $txn->is_done, '... and commits'
    or diag($txn->is_failed ? $txn->failure : "still pending");
  is_deeply [ $txn->is_done ? $txn->get : () ], [ 1 ], '... with the result of its own statement';
  is scalar $admin->selectrow_array("SELECT v FROM `$T` WHERE id = 1"), 101,
    '... which the server applied once';

  my @r = child_report($c);
  is "@r", '0 1', 'in the child the transaction stayed pending and nothing was released';

  my $again = $async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async("UPDATE `$T` SET v = v + 1 WHERE id = ?", [ 1 ]);
  });
  ok wait_until(sub { $again->is_ready }, 5), 'the next transaction completes';
  ok $again->is_done, '... and commits';
  is scalar $admin->selectrow_array("SELECT v FROM `$T` WHERE id = 1"), 102, '... applied';

  pool_still_serves();
  $locker->disconnect;
};

# Fork a child that uses the pool before its loop has run: $pool->acquire is
# the first thing it does. It writes two lines into a pipe -- one when the
# session it was given has answered, one after it ran the loop for a while
# longer -- and leaves through POSIX::_exit.
sub fork_acquiring_child {
  my ($report) = @_;
  pipe(my $rd, my $wr) or die "pipe: $!";
  my $child = fork;
  die "fork: $!" unless defined $child;
  unless ($child) {
    $SIG{ALRM} = sub { POSIX::_exit(4) };
    alarm 30;
    close $rd;
    my $say = sub { syswrite $wr, join("\t", map { s/[\t\n]/ /gr } @_) . "\n" };
    eval {
      my $got     = $pool->acquire;   # nothing of the loop has run in the child
      my $adopted = ($pool->{_owner_pid} // 0) == $$ ? 1 : 0;
      my @up = ('failed', $adopted, 'the acquire did not complete');
      if (wait_until(sub { $got->is_ready }, 10)) {
        my ($mdb) = $got->is_done ? $got->get : ();
        my ($rows, $err);
        $mdb->query('SELECT CONNECTION_ID()', sub { ($rows, $err) = @_; $err //= '' }) if $mdb;
        wait_until(sub { defined $err }, 10) if $mdb;
        @up = !$mdb         ? ('failed', $adopted, 'the acquire failed: ' . $got->failure)
            : !defined $err ? ('failed', $adopted, 'its SELECT was not answered')
            : length $err   ? ('failed', $adopted, "its SELECT failed: $err")
            :                 ('up', $adopted, $rows->[0][0], $mdb->thread_id);
      }
      $say->(@up);
      wait_until(sub { 0 }, 1.5);   # the lock is released while this loop runs
      $say->($report->());
      1;
    } or $say->('died', "$@");
    POSIX::_exit(0);   # no END: the parent's sessions and table stay its own
  }
  close $wr;
  my %c = (rd => $rd, buf => '');
  $c{reaper} = EV::child($child, 0, sub { $c{status} = $_[0]->rstatus });
  return \%c;
}

# The next line the child wrote, read WITHOUT running the loop: the parent
# stays out of it. Empty when the child wrote none in time, or is gone.
sub child_line {
  my ($c, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  while ($c->{buf} !~ /\n/) {
    my $left = $deadline - Time::HiRes::time();
    return () if $left <= 0;
    my $rin = '';
    vec($rin, fileno $c->{rd}, 1) = 1;
    next unless select(my $rout = $rin, undef, undef, $left) > 0;   # or a signal: the child exited
    my $n = sysread $c->{rd}, $c->{buf}, 4096, length $c->{buf};
    next if !defined $n && $!{EINTR};
    return () unless $n;
  }
  $c->{buf} =~ s/\A([^\n]*)\n//;
  return split /\t/, $1;
}

sub sessions_alive {
  my (@tids) = @_;
  return scalar $admin->selectrow_array(
    'SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID IN ('
      . join(', ', ('?') x @tids) . ')', undef, @tids);
}

subtest 'c) a child that acquires before its loop runs, with a query in flight and a transaction pinned' => sub {
  plan skip_all => 'core before k233: a forked child does not take the pool over'
    unless DBIO::Storage::PoolBase->can('_verify_pid');

  my $v      = $admin->selectrow_array("SELECT v FROM `$T` WHERE id = 1");
  my $locker = raw();
  $locker->do("LOCK TABLES `$T` WRITE");

  # The handles are held weakly from here on: in the child only the statements
  # in flight keep the parent's handles alive, as in a program.
  my ($f, $qconn) = dispatch_on_one(sub {
    $async->_query_async("SELECT id, v, CONNECTION_ID(), ? FROM `$T` WHERE id = ?", [ 31, 1 ]);
  });
  ok $qconn, 'the query runs on a connection checked out from the pool';
  my $qtid = $qconn ? $qconn->thread_id : 0;
  Scalar::Util::weaken($qconn);

  my ($txn, $tconn) = dispatch_on_one(sub {
    $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("INSERT INTO `$T` (id, v) VALUES (?, ?)", [ 2, 560 ])->then(sub {
        $ctx->_query_async("SELECT CONNECTION_ID(), v FROM `$T` WHERE id = ?", [ 2 ]);
      });
    });
  });
  ok $tconn, 'the transaction pins the other pooled connection';
  my $ttid = $tconn ? $tconn->thread_id : 0;
  Scalar::Util::weaken($tconn);

  ok wait_until(sub {
    !grep { processlist_state($admin, $_) !~ /lock/i } $qtid, $ttid;
  }, 5), '... and both statements wait for the lock on the server';
  is $pool->available, 0, '... so the parent has no idle connection at fork time';

  my $c = fork_acquiring_child(sub {
    return (
      ($f->is_ready ? 1 : 0), ($txn->is_ready ? 1 : 0),
      scalar @{ $pool->{_connections} },
      map { defined $_ ? $_->socket : 'freed' } $qconn, $tconn,
    );
  });

  # From here to the end of release_lock_to_the_child the parent stays out of
  # the loop: the child's loop meets whatever arrives on a shared socket first.
  my ($up, $adopted, $tid, $handle_tid) = child_line($c, 15);
  is $up, 'up', 'the child\'s acquire, called before its loop ran, gave it a connection that answers'
    or diag('the child said: ' . join(' ', map { $_ // '' } $up, $adopted, $tid));
  is $adopted, 1, '... its first acquire took the pool over (core k233)';
  $tid = 0 unless ($up // '') eq 'up' && ($tid // '') =~ /\A[0-9]+\z/;
  is $handle_tid, $tid, '... SELECT CONNECTION_ID() names the session of the handle it was given';
  ok $tid && !grep({ $_ == $tid } @TIDS), '... a new session, neither of the parent\'s'
    or diag("child: $tid, parent: @TIDS");
  is sessions_alive($tid), 1, '... and one of its own on the server';

  release_lock_to_the_child($locker);
  my @r = child_line($c, 0.01);
  ok !@r, 'the lock was released while the child\'s loop was still running';

  ok wait_until(sub { $f->is_ready }, 5), 'the query in flight at fork time completes in the parent';
  ok $f->is_done, '... successfully'
    or diag($f->is_failed ? $f->failure : "still pending");
  is_deeply [ $f->is_done ? $f->get : () ], [ [ 1, $v, $qtid, 31 ] ],
    '... with its own rows, from its own session';

  ok wait_until(sub { $txn->is_ready }, 5), 'the transaction in flight at fork time completes in the parent';
  ok $txn->is_done, '... and commits'
    or diag($txn->is_failed ? $txn->failure : "still pending");
  is_deeply [ $txn->is_done ? $txn->get : () ], [ [ $ttid, 560 ] ],
    '... with the result of its own statements, from its own session';
  is scalar $admin->selectrow_array("SELECT v FROM `$T` WHERE id = 2"), 560,
    '... and its row is there';

  @r = child_line($c, 5) unless @r;
  is scalar(@r), 5, 'the child reported after its loop had run on'
    or diag("the child said: @r");
  push @r, ('') x (5 - @r);
  is "@r[0, 1]", '0 0', 'in the child the query and the transaction stayed pending';
  is $r[2], 1, '... its pool holds the one connection it opened';
  is "@r[3, 4]", '-1 -1',
    '... and it dropped its copies of both parent handles, though the pool no longer held them';
  ok wait_until(sub { defined $c->{status} }, 5), 'the child exited';
  is(($c->{status} // -1) >> 8, 0, '... normally');

  is sessions_alive($qtid, $ttid), 2, 'both of the parent\'s sessions outlived the child';
  is $pool->{_owner_pid}, $$, '... and the parent still owns its pool';
  pool_still_serves();
  $locker->disconnect;
};

$h->disconnect;
$admin->disconnect;
done_testing;

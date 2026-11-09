use strict;
use warnings;
use Test::More;
use POSIX ();

# LIVE regression for karr k45: a forked child and the parent's pooled
# connections, against a real PostgreSQL. t/34-pool-fork-guard-mock.t proves
# the same claims offline, down to the bytes the server receives; this file
# shows what they cost against a real backend.
#
# Measured at HEAD before the fix (PostgreSQL 18.6, EV::Pg 0.07):
#   * a child that resumed the EV loop read the reply to the parent's statement
#     in flight -- the child's copy of the parent's Future completed with the
#     parent's row -- and the parent's statement never completed; the pool of
#     one it ran on stayed checked out, so the next statement waited forever;
#   * a child that did nothing but exit ended the parent's session: EV::Pg's
#     destructor calls PQfinish, which sends Terminate on the socket the child
#     shares with the parent. The parent's next statement failed with
#     "connection lost" and its backend was gone from pg_stat_activity. A
#     statement in flight at fork completed, and the session died after it.
#
# What this file claims:
#   1. With a pooled query and a pinned transaction each in flight at fork, a
#      child that resumes the loop leaves both alone: in the child neither
#      Future settles; in the parent the query returns its own row, the
#      transaction commits with its own, and both connections serve the next
#      statement on the same backends, which are still alive.
#   2. A child that exits -- with a statement of the parent in flight on one
#      connection and the other idle -- leaves both sessions alone: the
#      statement returns its row, and both connections serve the next statement
#      on the same, still-alive backends.
# Every wait is bounded by a keepalive(0) watchdog; alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;
use File::Temp ();

alarm 300;

my $REPORT = File::Temp->new;

# (1, @result) once $f is done, (0, $error) once it failed or after 10 seconds.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

sub run_loop_for {
  my ($secs) = @_;
  my $done = 0;
  EV::now_update();
  my $t = EV::timer($secs, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The backend pid of each of the pool's $n connections, all of them held at
# once so each is a different connection. undef where the connection is gone.
sub backend_pids {
  my ($h, $n) = @_;
  my $pool = $h->pool;
  my @conns = map { my ($ok, $pg) = wait_for($pool->acquire); $ok ? $pg : undef } 1 .. $n;
  my @pids;
  for my $pg (@conns) {
    my ($ok, $row) = $pg ? eval { wait_for($h->query_on($pg, 'SELECT pg_backend_pid()')) } : (0);
    push @pids, $ok ? $row->[0] : undef;
  }
  $pool->release($_) for grep { defined } @conns;
  return [ sort { $a <=> $b } map { $_ // 0 } @pids ];
}

sub alive {
  my ($h, $pids) = @_;
  return $h->sync_storage->dbh->selectrow_array(
    'SELECT count(*) FROM pg_stat_activity WHERE pid = ANY(?)', undef, $pids,
  );
}

sub run_child {
  my ($code) = @_;
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  unless ($pid) {
    alarm 30;
    $code->();
    POSIX::_exit(0);
  }
  waitpid $pid, 0;
  return $? >> 8;
}

# --- 1. a child resumes the loop -----------------------------------------------

{
  my $h  = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 2 });
  my $as = $h->async;
  my $before = backend_pids($h, 2);
  is alive($h, $before), 2, 'two pooled connections, two live backends';

  my $query = $as->_query_async('SELECT pg_sleep(0.5), 42');
  my $txn   = $as->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SELECT pg_sleep(0.5), 7', []);
  });
  run_loop_for(0.2);   # BEGIN is done, both statements are running
  is $h->pool->available, 0, 'a pooled query and a pinned transaction are in flight';

  is run_child(sub {
    # Long enough for both replies to arrive.
    EV::now_update();
    my $t = EV::timer(1.5, 0, sub { EV::break(EV::BREAK_ALL()) });
    EV::run();
    open my $fh, '>', $REPORT->filename or POSIX::_exit(2);
    print {$fh} join("\t", ($query->is_ready ? 1 : 0), ($txn->is_ready ? 1 : 0)), "\n";
    close $fh;
  }), 0, 'the child resumed the loop and exited';

  open my $fh, '<', $REPORT->filename or die "report: $!";
  chomp(my $line = <$fh> // '');
  is $line, "0\t0", 'in the child neither the query\'s nor the transaction\'s Future settled';

  my ($ok, @rows) = wait_for($query);
  ok $ok, 'in the parent the query completed' or diag $rows[0];
  is $ok && $rows[0][1], 42, '... with its own row';
  ($ok, @rows) = wait_for($txn);
  ok $ok, 'the transaction committed' or diag $rows[0];
  is $ok && $rows[0][1], 7, '... with the row of its own statement';

  is_deeply backend_pids($h, 2), $before, 'both connections serve the next statement on the same backends';
  is alive($h, $before), 2, '... which are still alive';

  $h->disconnect;
}

# --- 2. a child exits ----------------------------------------------------------

{
  my $h  = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 2 });
  my $as = $h->async;
  my $before = backend_pids($h, 2);

  my $query = $as->_query_async('SELECT pg_sleep(0.3), 44');
  run_loop_for(0.1);
  is $h->pool->available, 1, 'a statement in flight on one connection, the other idle';

  is run_child(sub { exit 0 }), 0, 'a child exited';

  my ($ok, @rows) = wait_for($query);
  ok $ok, 'the statement in flight at fork completed' or diag $rows[0];
  is $ok && $rows[0][1], 44, '... with its own row';

  is_deeply backend_pids($h, 2), $before, 'both connections serve the next statement on the same backends';
  is alive($h, $before), 2, '... which are still alive';

  $h->disconnect;
}

done_testing;

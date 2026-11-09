use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for $txn_ctx->pipeline inside txn_do_async (karr k41, core k213).
#
# Since core k213 DBIO::Storage::Async::TransactionContext::pipeline runs the
# pipeline bracket on the transaction's PINNED connection (through
# DBIO::Storage::Async::_pipeline_on_conn) and does not release it -- only the
# transaction boundary does. $txn_ctx->txn_do_async refuses with a
# DBIO::Exception instead of opening an independent transaction on a second
# pool connection. t/15-pipeline-facade-live.t only drives $storage->pipeline;
# nothing live proved the in-transaction form. We assert:
#
#   (a) the pipeline batch runs on the SAME backend as the transaction:
#       pg_backend_pid() read inside the batch equals pg_backend_pid() read on
#       the transaction context, and the batch is pinned to the very txn_conn;
#   (b) a rolled-back transaction takes its pipeline writes with it -- they are
#       invisible to an independent observer connection, before and after;
#   (c) a committed transaction makes them visible to that observer, and only
#       after COMMIT (not while the transaction is still open);
#   (d) $txn_ctx->txn_do_async throws a DBIO::Exception;
#   (e) afterwards that exact connection (found by its remembered PID) is back
#       on the idle stack with no open transaction and pipeline mode off, as
#       seen by libpq on the handle and by the server in pg_stat_activity.
#
# Why this goes RED on the pre-k213 behaviour: $txn_ctx->pipeline delegated to
# $storage->pipeline, which acquired a SECOND pool connection. The pool is
# pre-warmed below to hold >= 2 connections, so that other connection is always
# a different backend -> (a) sees a different PID; its writes run outside the
# BEGIN on the txn connection and are autocommitted -> the observer sees them
# while the transaction is still open and they survive the ROLLBACK -> (b)/(c)
# fail. The old $txn_ctx->txn_do_async opened that independent transaction
# silently instead of throwing -> (d) fails.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
  plan skip_all => 'EV::Pg not installed'
    unless eval { require EV::Pg; 1 };
}

use EV;
use EV::Pg;
use Scalar::Util ();
use DBIO::PostgreSQL::EV::Storage;

# The test login as the libpq parameters the transport reads it as; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

# The file's backstop: a hang anywhere in it ends the process. A guarded wait
# has a timeout of its own and leaves this alarm running (karr k88).
alarm 120;

sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 15, "TIMEOUT awaiting $what\n");
}

my $table = 'dbio_k41_txn_ctx_pipeline';

# The storage under test, with room for more than one pooled connection.
my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { %ci, pool_size => 4 }, {} ]);
my $pool = $storage->pool;

# An independent observer with a pool of its own: whatever it sees is what a
# different session sees, never the transaction's own view.
my $observer = DBIO::PostgreSQL::EV::Storage->new(undef);
$observer->connect_info([ { %ci, pool_size => 1 }, {} ]);

sub observe {
  my ($sql, @bind) = @_;
  return await_guarded($observer->_query_async($sql, \@bind), "observer: $sql")->get;
}

sub observed_names {
  my ($like) = @_;
  return map { $_->[0] }
    observe("SELECT name FROM $table WHERE name LIKE ? ORDER BY name", $like);
}

my ($observer_pid) = map { $_->[0] } observe('SELECT pg_backend_pid()');

observe("DROP TABLE IF EXISTS $table");
observe("CREATE TABLE $table (id serial PRIMARY KEY, name text)");

# Pre-warm: hold two connections at once so the pool really has two distinct
# backends. With only one, the old "pipeline on a foreign pool connection"
# path could not pick a different backend and (a) would pass for free.
{
  my @held = await_guarded(
    Future->needs_all(map { $pool->acquire } 1 .. 2), 'pre-warm acquire',
  )->get;
  my @pids = map { $_->backend_pid } @held;
  $pool->release($_) for @held;
  isnt $pids[0], $pids[1], "pool holds two distinct backends (@pids)";
}
cmp_ok $pool->size, '>=', 2, 'pool has at least 2 connections';
PoolReset->until_reset($pool);   # idle once the reset of the borrow is answered (karr k99)
cmp_ok $pool->available, '>=', 2, 'both are idle before the transactions';

# Run one transaction that issues its writes through $t->pipeline. $finish
# decides how the coderef ends: 'commit' returns normally, 'rollback' fails.
sub run_txn {
  my ($tag, $finish) = @_;
  my %seen;

  my $f = $storage->txn_do_async(sub {
    my ($t) = @_;
    $seen{txn_conn} = $t->txn_conn;

    return $t->_query_async('SELECT pg_backend_pid()', [])->then(sub {
      $seen{txn_pid} = $_[0][0];

      # (d) nested txn_do_async on the context refuses, synchronously.
      eval { $t->txn_do_async(sub { Future->done }) };
      $seen{nested_error} = $@;

      return $t->pipeline(sub {
        my ($batch) = @_;
        $seen{batch_conn}       = $batch->pipeline_conn;
        $seen{pipeline_status}  = $batch->pipeline_conn->pipeline_status;
        return $batch->future_class->needs_all(
          $batch->_query_async('SELECT pg_backend_pid()', []),
          map { $batch->insert_async($table, { name => "$tag-$_" }) } 1 .. 3,
        );
      });
    })->then(sub {
      my ($pid_row) = @_;
      $seen{batch_pid} = $pid_row->[0];
      # Inside the transaction its own view sees the batch writes ...
      return $t->_query_async(
        "SELECT count(*) FROM $table WHERE name LIKE ?", ["$tag-%"],
      );
    })->then(sub {
      $seen{inside_count} = $_[0][0];
      # ... while an independent session must not, until COMMIT.
      return $observer->_query_async(
        "SELECT count(*) FROM $table WHERE name LIKE ?", ["$tag-%"],
      );
    })->then(sub {
      $seen{outside_count_during} = $_[0][0];
      return $finish eq 'commit'
        ? Future->done('committed')
        : Future->fail("rollback-$tag\n");
    });
  });

  await_guarded($f, "txn_do_async ($tag)");
  return ($f, \%seen);
}

# Connection-state checks after the transaction, on the connection with the
# remembered PID.
sub check_clean {
  my ($tag, $seen) = @_;
  my $pid = $seen->{txn_pid};

  my ($conn) = grep { $_->backend_pid == $pid } @{ $pool->{_connections} };
  ok $conn, "$tag (e): connection with backend PID $pid is still in the pool";
  is Scalar::Util::refaddr($conn), Scalar::Util::refaddr($seen->{txn_conn}),
    "$tag (e): it is the handle the transaction pinned";
  ok scalar(grep { Scalar::Util::refaddr($_) == Scalar::Util::refaddr($conn) }
    @{ $pool->{_idle} }),
    "$tag (e): released back onto the idle stack";
  is $conn->transaction_status, EV::Pg::PQTRANS_IDLE(),
    "$tag (e): libpq transaction status is IDLE (no open txn)";
  is $conn->pipeline_status, EV::Pg::PQ_PIPELINE_OFF(),
    "$tag (e): libpq pipeline mode is OFF";
  my ($state) = map { $_->[0] }
    observe('SELECT state FROM pg_stat_activity WHERE pid = ?', $pid);
  is $state, 'idle', "$tag (e): server reports backend $pid as 'idle'";
}

# --- ROLLBACK ---------------------------------------------------------------

{
  my ($f, $seen) = run_txn('rb', 'rollback');

  ok $f->is_failed, 'rollback: txn Future failed';
  is +($f->failure // ''), "rollback-rb\n", 'rollback: with the coderef error';

  diag "rollback: txn pid=$seen->{txn_pid} batch pid=$seen->{batch_pid} observer pid=$observer_pid";
  is $seen->{batch_pid}, $seen->{txn_pid},
    'rollback (a): pg_backend_pid() in the batch equals the transaction backend';
  is Scalar::Util::refaddr($seen->{batch_conn}),
     Scalar::Util::refaddr($seen->{txn_conn}),
    'rollback (a): batch is pinned to the transaction connection';
  isnt $seen->{txn_pid}, $observer_pid, 'observer is a different backend';
  is $seen->{pipeline_status}, EV::Pg::PQ_PIPELINE_ON(),
    'rollback: the batch ran in libpq pipeline mode';

  isa_ok $seen->{nested_error}, 'DBIO::Exception',
    'rollback (d): $ctx->txn_do_async threw';
  like "$seen->{nested_error}", qr/nested txn_do_async/,
    'rollback (d): refusal names the nested transaction';

  is $seen->{inside_count}, 3, 'rollback: the txn sees its 3 pipeline writes';
  is $seen->{outside_count_during}, 0,
    'rollback (b): observer sees none of them while the txn is open';
  is_deeply [ observed_names('rb-%') ], [],
    'rollback (b): pipeline writes are gone after ROLLBACK';

  check_clean('rollback', $seen);
}

# --- COMMIT -----------------------------------------------------------------

{
  my ($f, $seen) = run_txn('cm', 'commit');

  ok $f->is_done, 'commit: txn Future resolved';
  is $f->get, 'committed', 'commit: with the coderef result';

  diag "commit: txn pid=$seen->{txn_pid} batch pid=$seen->{batch_pid} observer pid=$observer_pid";
  is $seen->{batch_pid}, $seen->{txn_pid},
    'commit (a): pg_backend_pid() in the batch equals the transaction backend';
  is Scalar::Util::refaddr($seen->{batch_conn}),
     Scalar::Util::refaddr($seen->{txn_conn}),
    'commit (a): batch is pinned to the transaction connection';

  isa_ok $seen->{nested_error}, 'DBIO::Exception',
    'commit (d): $ctx->txn_do_async threw';

  is $seen->{inside_count}, 3, 'commit: the txn sees its 3 pipeline writes';
  is $seen->{outside_count_during}, 0,
    'commit (c): observer sees none of them before COMMIT';
  is_deeply [ observed_names('cm-%') ], [qw(cm-1 cm-2 cm-3)],
    'commit (c): observer sees all pipeline writes after COMMIT';

  check_clean('commit', $seen);
}

# --- cleanup ----------------------------------------------------------------

observe("DROP TABLE IF EXISTS $table");
$storage->disconnect;
$observer->disconnect;

done_testing;

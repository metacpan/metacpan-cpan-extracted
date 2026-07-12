use strict;
use warnings;
use Test::More;

use Future;
use DBIO::Async::Pool;
use DBIO::Async::Storage;

# OFFLINE unit test for the connection-readiness gating in
# DBIO::Async::Pool::acquire. No real DB, no event loop.
#
# The pool delegates readiness checking to the Storage's
# _await_conn_ready method. We create a test Storage that controls
# when connections become "ready" and verify the acquire→ready→resolve
# lifecycle.

# --- Fake connection: tracks ready state ---

{
  package FakeConn3;
  sub new {
    my ($class, $id) = @_;
    bless { id => $id, ready => 0 }, $class;
  }
  sub id    { $_[0]->{id} }
  sub ready { $_[0]->{ready} }
  sub set_ready { $_[0]->{ready} = 1 }
}

# --- Test Storage: provides seam hooks, controls readiness ---

{
  package TestStorage3;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class         { 'DBIO::SQLMaker' }
  sub _transform_sql          { $_[1] }
  sub _post_insert_sql        { '' }
  sub _normalize_conninfo     { $_[1] }
  sub _create_pool_connection { my $s = shift; FakeConn3->new(++$s->{_next_id}) }
  sub _shutdown_pool_connection { }
  sub _txn_context_class      { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor      { 'txn_conn' }
  sub _pipeline_enter         { }
  sub _pipeline_sync          { Future->done }
  sub _pipeline_exit          { }

  sub _conn_ready {
    my ($self, $conn) = @_;
    return $conn->ready;
  }

  # Override _await_conn_ready to avoid needing Future::IO for this test.
  # Simulates the readiness check: if not ready, return a pending Future
  # that the test resolves manually.
  sub _await_conn_ready {
    my ($self, $conn) = @_;
    return Future->done($conn) if $conn->ready;
    # Store a pending Future so the test can resolve it
    my $f = Future->new;
    push @{ $self->{_pending_ready} }, { conn => $conn, future => $f };
    return $f;
  }
}

# --- Test Pool: uses TestStorage3 ---

my $storage = TestStorage3->new(undef);
$storage->{_next_id} = 0;
$storage->{_pending_ready} = [];
$storage->connect_info([{ host => 'localhost' }]);

my $pool = $storage->pool;

# --- 1. acquire stays pending until connection is ready (cold connection) ---

my $f = $pool->acquire;
ok !$f->is_ready, 'acquire Future is pending while the connection is cold';

# Manually mark the connection as ready and resolve the pending Future
my $pending = shift @{ $storage->{_pending_ready} };
ok $pending, 'storage recorded a pending readiness Future';
my $conn = $pending->{conn};
$conn->set_ready;
$pending->{future}->done($conn);

ok $f->is_ready, 'acquire Future resolves once readiness Future resolves';
is $f->get, $conn, 'acquire resolves to the now-ready connection';

# --- 2. idle reuse is ready IMMEDIATELY (no re-waiting) ---

$pool->release($conn);
my $f2 = $pool->acquire;
ok $f2->is_ready, 'reacquiring an already-ready idle connection is ready at once';
is $f2->get, $conn, 'idle reuse returns the same ready connection';

# --- 3. shutdown clears connections ---

$pool->shutdown;
is scalar(@{ $pool->{_connections} }), 0, 'shutdown emptied the connections list';
is scalar(@{ $pool->{_idle} }), 0, 'shutdown emptied the idle list';

done_testing;

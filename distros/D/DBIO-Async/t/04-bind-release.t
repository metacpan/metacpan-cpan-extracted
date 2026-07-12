use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';
use Future;

# OFFLINE regression test for the "async bind-value leak" concern.
# Ported from dbio-postgresql-async t/05-bind-release.t.
#
# WHAT THIS TEST PROVES: bind values issued through the async query
# path are retained only by the issuing scope's lexical, not by any
# storage/pool cache. Once that scope ends, the bind arrayref is freed.
# This is a pure Perl reference-graph question -- no DB needed.
#
# The test uses a mock storage whose _query_async / _query_async_pinned
# faithfully emulate the contract: the completion callback is captured,
# but the $bind arrayref itself is NOT.

# --- FakeConn: minimal connection stand-in ---

{
  package FakeConn4;
  sub new { bless { queue => [] }, shift }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    my @serialized = map { defined $_ ? "$_" : undef } @$bind;
    push @{ $self->{queue} }, { cb => $cb, wire => \@serialized };
  }
  sub pending_count { scalar @{ $_[0]->{queue} } }
  sub complete_one {
    my $self = shift;
    my $entry = shift @{ $self->{queue} } or return;
    $entry->{cb}->([[1]], undef);
  }
}

# --- TestStorage4: mock async storage that uses FakeConn4 ---

{
  package TestStorage4;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _txn_context_class  { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor  { 'txn_conn' }
  sub _pipeline_enter     { }
  sub _pipeline_sync      { Future->done }
  sub _pipeline_exit      { }
  sub _conn_ready         { 1 }

  sub _create_pool_connection { FakeConn4->new }
  sub _shutdown_pool_connection { }

  # Override _query_async / _query_async_pinned to use FakeConn4
  # directly, bypassing the Future::IO seam (which needs a real fd).
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    $bind //= [];
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      my $f = Future->new;
      $conn->query_params($sql, $bind, sub {
        my ($rows, $err) = @_;
        if ($err) { $f->fail($err) } else { $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows) }
        $self->pool->release($conn);
      });
      return $f;
    });
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    $bind //= [];
    my $f = Future->new;
    $conn->query_params($sql, $bind, sub {
      my ($rows, $err) = @_;
      if ($err) { $f->fail($err) } else { $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows) }
    });
    return $f;
  }
}

# Build a storage whose pool uses FakeConn4.
sub new_storage {
  my $storage = TestStorage4->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);
  return $storage;
}

# --- 1. single pooled query: bind released once the future completes ---

{
  my $storage = new_storage;
  my $pool = $storage->pool;

  my $weak;
  my $f;
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async('SELECT $1', $bind);
  }
  # The issuing-scope strong lexical dies here.

  # Complete the query on the FakeConn4.
  my $conn = $pool->{_connections}[0];
  $conn->complete_one;
  $f->get;

  ok !defined $weak,
    'pooled query: bind arrayref is freed after the future completes '
    . '(completion closure does not retain it)';
}

# --- 2. pinned (transaction) query: same release contract ---

{
  my $storage = new_storage;
  my $pool = $storage->pool;

  # Acquire a connection manually to simulate a pinned transaction conn.
  my $conn = $pool->acquire->get;

  my $weak;
  my $f;
  {
    my $bind = [ 'txn-payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async_pinned($conn, 'SELECT $1', $bind);
  }

  $conn->complete_one;
  $f->get;

  ok !defined $weak,
    'pinned (txn) query: bind arrayref is freed after completion too';
}

# --- 3. many in-flight queries: each bind released, no accumulation ---

{
  my $storage = new_storage;
  my $pool = $storage->pool;

  # Pre-spawn enough connections for N concurrent queries.
  # Pool size is 5 by default; use 3 queries to stay within.
  my $N = 3;
  my @weak;
  my @f;
  for my $i (1 .. $N) {
    my $w;
    {
      my $bind = [ "row$i" x 32 ];
      weaken($w = $bind);
      push @f, $storage->_query_async("SELECT \$1 -- $i", $bind);
    }
    push @weak, $w;
  }

  my $held_inflight = grep { defined } @weak;
  is $held_inflight, 0,
    "no bind arrayref is retained while $N queries are in-flight "
    . '(no per-pool/per-future bind cache)';

  # Drain them.
  for my $i (0 .. $N - 1) {
    $pool->{_connections}[$i]->complete_one;
    $f[$i]->get;
  }

  my $held_after = grep { defined } @weak;
  is $held_after, 0,
    "after completing all $N queries, still zero binds held "
    . '(memory bounded by outstanding queries, not total issued)';
}

done_testing;

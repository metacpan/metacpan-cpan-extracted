use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';
use Future;

# OFFLINE regression test for karr k9 + karr k11 (ADR 0044: async bind lifetime
# ends at dispatch).
# Ported from dbio-postgresql-async t/05-bind-release.t.
#
# WHAT THIS TEST PROVES: the caller's bind arrayref is NOT retained by the
# async path -- neither while a query is in flight nor after the future
# settles. The transport serializes the bind values into its own wire buffer
# at dispatch (the DBD's query_params contract); the Perl arrayref's life
# ends there. This is a pure Perl reference-graph question -- no DB needed.
#
# WHAT RUNS FOR REAL: _query_async, _query_async_pinned AND _await_query_result
# from DBIO::Async::Storage -- the whole transport, including the dispatch
# closure and the collect callback. Until karr k11 this test overrode
# _await_query_result itself, i.e. exactly the seam the property lives in, so a
# green run only ever proved the _release_on_ready half (house rule 11).
#
# THE ONE SUBSTITUTION is _await_readable: instead of Future::IO->poll on a
# real socket fd it hands back a Future the TEST completes. That is faithful to
# what the production seam contributes to the reference graph -- a PENDING
# Future that holds the ->then callback until the socket is readable -- and it
# keeps the assertion deterministic: Future::IO auto-routes to whichever
# Future::IO::Impl::* happens to be installed, so a real pipe() would exercise
# a different implementation on every box.
#
# The load-bearing assertion is the IN-FLIGHT probe: after dispatch, while the
# query is still flying, NO callback may point at the caller's arrayref. Both
# halves of ADR 0044 are sampled by it -- a release callback built inside the
# acquire chain (karr k9) and a collect callback built inside the dispatch
# block (karr k11) each pin the bind capture alive through CvOUTSIDE, and each
# turns the probe red.

# --- BindMock: a concrete transport over an in-memory "wire" ---

{
  package BindMock;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

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

  sub _create_pool_connection   { { wire => [] } }
  sub _shutdown_pool_connection { }

  # The single transport substitution (see header): stands in for
  # Future::IO->poll($fh, POLLIN) with a Future the test completes by hand.
  sub _await_readable {
    my ($self, $conn) = @_;
    return $conn->{readable} = Future->new;
  }

  # DB-specific seam: serialize the binds onto the wire (the DBD
  # query_params contract) and keep no reference to the arrayref itself.
  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $conn->{wire} }, {
      sql  => $sql,
      bind => [ map { defined $_ ? "$_" : undef } @$bind ],
    };
    return;
  }

  # DB-specific seam, post karr k11: handed the connection and NOTHING else.
  # Record the arity so the signature change is pinned by a test, not only by
  # the POD.
  sub _collect_result {
    my $self = shift;
    push @{ $self->{collect_arity} }, scalar @_;
    return Future->done([1]);
  }
}

# Build a storage whose pool hands out BindMock connections.
sub new_storage {
  my $storage = BindMock->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);
  return $storage;
}

# "The socket became readable" -- resolve the pending _await_readable Future.
sub make_readable { $_[0]->{readable}->done }

# --- 1. single pooled query: bind released at dispatch, and after ---

{
  my $storage = new_storage;
  my $pool = $storage->pool;

  my $weak;
  my $f;
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async('SELECT ?', $bind);
  }
  # The issuing-scope strong lexical dies here.

  my $conn = $pool->{_connections}[0];

  is scalar @{ $conn->{wire} }, 1,
    'pooled query: the query really was dispatched to the wire';
  is $conn->{wire}[0]{bind}[0], 'payload' x 64,
    'pooled query: the bind values reached the wire (serialized at dispatch)';

  ok !defined $weak,
    'pooled query: bind arrayref is freed WHILE THE QUERY IS IN FLIGHT '
    . '(neither the dispatch closure nor the collect callback retains it)';

  make_readable($conn);
  $f->get;

  ok !defined $weak,
    'pooled query: bind arrayref is still freed after the future completes';

  is_deeply $storage->{collect_arity}, [1],
    '_collect_result is handed the connection and nothing else '
    . '(ADR 0044 seam signature: _collect_result($conn))';
}

# --- 2. pinned (transaction) query: same release contract ---
# This block isolates the karr k11 half: _query_async_pinned goes straight to
# _await_query_result -- no pool acquire, no _release_on_ready anywhere.

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
    $f = $storage->_query_async_pinned($conn, 'SELECT ?', $bind);
  }

  is $conn->{wire}[0]{bind}[0], 'txn-payload' x 64,
    'pinned (txn) query: the bind values reached the wire';

  ok !defined $weak,
    'pinned (txn) query: bind arrayref is freed while the query is in flight '
    . '(the collect callback closes over the connection only)';

  make_readable($conn);
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
    my $bind = [ "row$i" x 32 ];
    push @weak, $bind;
    weaken($weak[-1]);   # weaken the array element IN PLACE -- no copy
    push @f, $storage->_query_async("SELECT ? -- $i", $bind);
  }

  my $held_inflight = grep { defined } @weak;
  is $held_inflight, 0,
    "no bind arrayref is retained while $N queries are in-flight "
    . '(no per-pool/per-future bind cache, no pending-callback capture)';

  # Drain them.
  for my $i (0 .. $N - 1) {
    my $conn = $pool->{_connections}[$i];
    is $conn->{wire}[0]{bind}[0], ('row' . ($i + 1)) x 32,
      'in-flight query ' . ($i + 1) . ': the bind values reached the wire';
    make_readable($conn);
    $f[$i]->get;
  }

  my $held_after = grep { defined } @weak;
  is $held_after, 0,
    "after completing all $N queries, zero binds held "
    . '(memory bounded by outstanding queries, not total issued)';
}

# --- 4. queued pinned queries (karr k33): held until dispatch, not after ---
# Statements on one pinned connection are serialised: the second waits until
# the first has settled. Waiting, it MUST hold its SQL and binds -- they have
# not been sent yet. The claim here is that the queue is the only thing that
# does, and only until the statement goes out: once dispatched it is freed
# while in flight, exactly as an unqueued one. A statement cancelled while it
# waits is never sent, and its binds go at the cancel.

{
  my $storage = new_storage;
  my $conn = $storage->pool->acquire->get;

  my ($weak_first, $weak_queued, $weak_cancelled);
  my ($first, $queued, $cancelled);
  {
    my $b1 = [ 'first' x 64 ];
    my $b2 = [ 'queued' x 64 ];
    my $b3 = [ 'cancelled' x 64 ];
    weaken($weak_first     = $b1);
    weaken($weak_queued    = $b2);
    weaken($weak_cancelled = $b3);
    $first     = $storage->_query_async_pinned($conn, 'SELECT ? -- 1', $b1);
    $queued    = $storage->_query_async_pinned($conn, 'SELECT ? -- 2', $b2);
    $cancelled = $storage->_query_async_pinned($conn, 'SELECT ? -- 3', $b3);
  }

  is scalar @{ $conn->{wire} }, 1,
    'queued: only the first statement is on the wire while it is in flight';
  ok !defined $weak_first,
    'queued: the dispatched statement\'s binds are freed while it is in flight';
  ok defined $weak_queued,
    'queued: the waiting statement\'s binds are held -- they are not sent yet';

  $cancelled->cancel;
  ok !defined $weak_cancelled,
    'queued: a waiting statement cancelled before its turn drops its binds at '
    . 'the cancel';

  make_readable($conn);
  $first->get;

  is scalar @{ $conn->{wire} }, 2,
    'queued: the first settled, the second went out';
  is $conn->{wire}[1]{bind}[0], 'queued' x 64,
    'queued: ... with its own bind values';
  ok !defined $weak_queued,
    'queued: once dispatched, the queued statement\'s binds are freed while it '
    . 'is in flight -- the queue keeps nothing past the dispatch';

  make_readable($conn);
  $queued->get;

  is scalar @{ $conn->{wire} }, 2,
    'queued: the cancelled statement never reached the wire';
  ok !exists $conn->{_dbio_async_queue},
    'queued: and the idle connection carries no queue state';
}

done_testing;

use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util qw(refaddr isweak);
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k30: a blocking call that has to wait for a pool
# connection waits, and drives the Future::IO loop while it does.
#
# WHY IT MATTERS. ADR 0001: a sync storage method is its async sibling run to
# completion with ->get. With the pool exhausted the call is queued on a pool
# waiter, and every ->then off a PENDING Future is made with that Future's own
# `new` -- so the whole chain up to the ->get is of the waiter's class. A plain
# Future cannot ->get while pending ("is not yet complete and does not provide
# ->await"): a sync call waiting for a slot croaked instead of waiting. The
# waiter is therefore DBIO::Async::Future, whose await drives Future::IO.
#
# The other half: a blocking wait that DIES (the built-in loop refuses to sit
# idle when nothing is on it -- the sync call made inside a txn block of a
# pool of one, whose holder is the caller itself) must not leave its waiter
# queued. Left there, the release of the connection hands it to a waiter nobody
# reads and the pool of one is wedged for good. The wait takes its waiter back
# (core PoolBase::_withdraw_waiter) and fails it.
#
# This file runs on the built-in Future::IO implementation (a process loads
# one; no Future::IO::Impl::* is loaded here). Under a real loop the
# unresolvable case hangs instead of dying -- upstream, not asserted.
#
# WHAT IS REAL. The whole transport, the real DBIO::Async::Pool, core's CRUD
# runner and sync wrappers. The mock owns the DB-specific seams only
# (section 0 pins that).

{
  package Wait35;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, [ $sql, $conn->{id} ];
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row', $conn->{id} ]);
  }
}

sub new_storage {
  my (%opts) = @_;
  my $storage = Wait35->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown);
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %opts }]);
  return $storage;
}

# ---------------------------------------------------------------------------
# 0. The guard: the mock owns the DB seams and nothing of the pool.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _await_query_result _await_readable pool)) {
  is refaddr(Wait35->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
isnt refaddr(DBIO::Async::Pool->can('_new_waiter')),
  refaddr(DBIO::Storage::PoolBase->can('_new_waiter')),
  'the pool answers core\'s _new_waiter seam itself';
is refaddr(DBIO::Async::Pool->can('_withdraw_waiter')),
  refaddr(DBIO::Storage::PoolBase->can('_withdraw_waiter')),
  '... and withdraws through core\'s _withdraw_waiter, which it does not replace';

# ---------------------------------------------------------------------------
# 1. The waiter's class: what the pool queues, and everything built on it.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $held = $pool->acquire->get;
  my $acq  = $pool->acquire;
  ok !$acq->is_ready, 'waiter: the second acquire of a pool of one is queued';
  my $waiter = $pool->{_waiters}[0];
  isa_ok $waiter, 'DBIO::Async::Future', 'waiter: the Future the pool queued';
  isa_ok $waiter, 'Future', '... a Future';
  isa_ok $acq->then(sub { Future->done(1) }), 'DBIO::Async::Future',
    'waiter: a ->then off the wait -- all that the blocking call ->gets';
  isa_ok $waiter->new, 'DBIO::Async::Future',
    'waiter: ->new on it makes another of the same class';

  my $other = $pool->_new_waiter;
  ok !$other->is_ready && refaddr($other) != refaddr($waiter),
    'waiter: _new_waiter answers a NEW pending Future each time';

  $acq->cancel;
  is scalar @{ $pool->{_waiters} }, 0, 'waiter: a cancel takes it out of the queue';
  $pool->release($held);
}

# ---------------------------------------------------------------------------
# 2. The k30 case: an async query holds the only connection, a sync call
#    waits for it, drives the loop, and gets its answer.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $held = $storage->_query_async('SELECT held', []);
  is_deeply $storage->{wire}, [ [ 'SELECT held', 1 ] ],
    'sync wait: the async query holds the one connection';

  my $got = eval { [ $storage->_query_async('SELECT sync', [])->get ] };
  is $@, '', 'sync wait: the blocking call does not croak';
  is_deeply $got, [ [ 'row', 1 ] ],
    'sync wait: ... it waited its turn and got the answer on the freed connection';
  is_deeply $storage->{wire}, [ [ 'SELECT held', 1 ], [ 'SELECT sync', 1 ] ],
    'sync wait: the held statement went first, the waiting one second, one connection';
  ok $held->is_ready, 'sync wait: the async caller\'s Future settled meanwhile';
  is $pool->size, 1, 'sync wait: the pool still has its one connection';

  # The public path: core's sync wrapper, the one the issue was met on.
  my $held2 = $storage->_query_async('SELECT held2', []);
  my $n = eval { $storage->update('artist', { name => 'x' }, { id => 1 }); 1 };
  is $@, '', 'sync wait: core\'s sync update waits for the held connection too';
  ok $n, '... and returns';
}

# ---------------------------------------------------------------------------
# 3. A blocking wait that dies takes its waiter back. The holder is the
#    caller itself (a txn block of a pool of one): nothing is on the loop,
#    the built-in implementation refuses to sit idle.
#    acquire_timeout 0 leaves the wait without a timer of core's: with the
#    default 30 seconds it would end in core's timeout, not in the dying wait
#    this section holds.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(acquire_timeout => 0);
  my $pool    = $storage->pool;

  my $held = $pool->acquire->get;      # the txn's connection: no statement in flight
  my $ok = eval { $storage->update('artist', { name => 'x' }, { id => 1 }); 1 };
  ok !$ok, 'dying wait: the blocking call dies ...';
  like $@, qr/Cowardly refusing to sit idle/,
    '... with the loop\'s own words -- nothing is rewritten';
  is scalar @{ $pool->{_waiters} }, 0,
    'dying wait: its waiter is no longer queued';

  $pool->release($held);
  my $again = $pool->acquire;
  ok $again->is_ready,
    'dying wait: the connection is there for the next acquire -- the pool is not wedged';
  is_deeply [ $again->get ], [ $held ], '... it is the very same connection';
  $pool->release($held);

  my $after = eval { [ $storage->_query_async('SELECT after', [])->get ] };
  is_deeply $after, [ [ 'row', 1 ] ],
    'dying wait: a later statement runs on it, as if nothing had happened';
  is_deeply $storage->{wire}, [ [ 'SELECT after', 1 ] ],
    'dying wait: the dead wait sent nothing';
  is_deeply $storage->{shutdown}, [], 'dying wait: no connection was lost';
}

# ---------------------------------------------------------------------------
# 4. The waiter's way back to the pool is weak: a caller still holding its
#    wait does not keep the pool alive (the pool holds the waiter).
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $held    = $pool->acquire->get;
  my $acq  = $pool->acquire;
  my $waiter = $pool->{_waiters}[0];
  my $derived = $acq->then(sub { Future->done });

  my ($mark_pool, $mark_waiter) = @{ $waiter->{dbio_async_pool_wait} };
  is refaddr($mark_pool), refaddr($pool), 'weak: the waiter is marked with its pool';
  ok isweak($waiter->{dbio_async_pool_wait}[0]),
    'weak: ... held weakly, the pool holds the waiter';
  ok isweak($waiter->{dbio_async_pool_wait}[1]),
    'weak: ... and the mark does not hold the waiter either';
  is refaddr($derived->{dbio_async_pool_wait}), refaddr($waiter->{dbio_async_pool_wait}),
    'weak: a Future derived from the wait carries the same mark';
  $derived->cancel;
}

done_testing;

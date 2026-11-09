use strict;
use warnings;
use Test::More;
use Test::Exception;

use Future;
use DBIO::Test;               # core's offline fake-storage schema harness
use DBIO::SQLMaker;
use DBIO::Storage::DBI;
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test for $rs->with_context($ctx) (core ADR 0045 / core karr k145) on
# THIS transport (karr k15 point 6). No DB, no event loop, no DBD -- the schema
# comes from core's fake DBIO::Test::Storage, and every async statement is
# dispatched on a pipe and awaited through the real Future::IO watcher seam.
#
# WHAT IS ALREADY COVERED ELSEWHERE, AND WHAT IS NOT. with_context itself is
# core's: it lives on ResultSet, Row and ResultSetColumn, and core's
# t/resultset/with_context.t drives all four of its acceptance consequences
# against a fully synchronous fake transport with a fake pool. None of that is
# repeated here. What core cannot show, because it has no pool, is the thing
# this dist is: that a context minted by THIS transport's txn_do_async, over a
# REAL DBIO::Async::Pool, routes a resultset's *_async onto the very connection
# BEGIN ran on -- and that an UNBOUND resultset, in the same block, takes a
# different pooled connection and runs outside the transaction. The second half
# is what makes the first half worth asserting: without the counter-case,
# "it ran on a connection" says nothing.
#
# WHY A TEST-ONLY ASYNC MODE. The mode name below is registered explicitly
# rather than using future_io, because future_io resolves its transport BY
# CONVENTION off the concrete driver storage (core k65/k67) -- for the fake
# DBIO::Test::Storage that would be DBIO::Test::Storage::Async, which does not
# and should not exist. Registering a test mode wires the same embedded-backend
# machinery (DBIO::Storage::DBI::_async_storage) to a real DBIO::Async::Storage
# subclass, which is the part under test. Core's own with_context test does the
# same thing for the same reason.

# --- CtxConn18 / CtxMock18: the transport, real except for the DB -----------

{
  package CtxMock18;
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
    return { r => $r, w => $w, id => ++$self->{_next_id} };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, { sql => $sql, conn => $conn->{id} };
    syswrite $conn->{w}, 'R';
    return;
  }

  # A read yields the configured rows; a write yields an affected-row count.
  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $b, 1;
    my $sql = $self->{wire}[-1]{sql};
    return Future->done(1) unless $sql =~ /^\s*SELECT/i;
    return Future->done(@{ $self->{rows} || [] });
  }
}

DBIO::Storage::DBI->register_async_mode( k15_ctx_transport => 'CtxMock18' );

my @ARTISTS = ( [ 1, 'Miles Davis', 13, undef ], [ 2, 'John Coltrane', 13, undef ] );

# Wire a fake-storage schema to a real transport backend, as
# connect(..., { async => ... }) would.
sub wired {
  my %args   = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('k15_ctx_transport');
  delete $schema->storage->{_async_storage_obj};

  my $backend = $schema->storage->_async_storage;
  # DBIO::Test::Storage carries no connect_info of its own, so give the pool
  # something to hand to _create_pool_connection (which ignores it).
  $backend->connect_info([{
    host => 'localhost', pool_size => $args{pool_size} // 1,
  }]);
  $backend->{_next_id} = 0;
  $backend->{wire}     = [];
  $backend->{rows}     = [ @ARTISTS ];
  return ($schema, $backend);
}

sub wire_for {
  my ($backend, $re) = @_;
  return grep { $_->{sql} =~ $re } @{ $backend->{wire} };
}

sub settle { my $f = shift; eval { $f->get }; return $f }

# ---------------------------------------------------------------------------
# 0. The machinery under the test really is this dist's.
# ---------------------------------------------------------------------------

{
  my ($schema, $backend) = wired();
  isa_ok $backend, 'DBIO::Async::Storage',
    'the embedded async backend core built';
  isa_ok $backend->pool, 'DBIO::Async::Pool', 'its pool';
}

# ---------------------------------------------------------------------------
# 1. Bound: the resultset runs on the PINNED connection, inside the bracket.
# ---------------------------------------------------------------------------

{
  my ($schema, $backend) = wired();

  my ($ctx, $rows);
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->all_async
                  ->then(sub { $rows = [@_]; return Future->done(scalar @_) });
  });

  is scalar(settle($f)->get), 2, 'the bound all_async resolved its rows';

  isa_ok $ctx, 'DBIO::Async::TransactionContext',
    'the context with_context was given';
  is scalar @$rows, 2, 'two rows came back';
  isa_ok $rows->[0], 'DBIO::Test::Schema::Artist',
    'and they still inflate to Result objects through the bound path';

  my ($select) = wire_for($backend, qr/^SELECT/);
  ok $select, 'the resultset issued its SELECT';
  is $select->{conn}, $ctx->txn_conn->{id},
    'the bound resultset ran on the PINNED connection -- the one BEGIN ran on '
    . '(ADR 0045: not a sibling pool connection outside the transaction)';

  is_deeply [ map { $_->{sql} =~ /^(BEGIN|COMMIT|ROLLBACK|SELECT)/ ? $1 : 'other' }
              @{ $backend->{wire} } ],
    [ 'BEGIN', 'SELECT', 'COMMIT' ],
    'and it ran INSIDE the bracket, between BEGIN and COMMIT';

  is scalar @{ $backend->pool->{_connections} }, 1,
    'the pool never had to spawn a second connection -- everything shared the '
    . 'pinned one';
}

# ---------------------------------------------------------------------------
# 2. The counter-case, in the same shape: UNBOUND, the resultset takes a
#    POOLED connection. This is the behaviour ADR 0045 exists to correct, and
#    without it section 1 would prove nothing -- a transport that ran
#    everything on one connection anyway would satisfy it by accident. The pool
#    is size 2 here so the unbound query can actually get a second connection
#    instead of queueing behind the pinned one forever.
# ---------------------------------------------------------------------------

{
  my ($schema, $backend) = wired(pool_size => 2);

  my ($ctx, $outside);
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    $outside = $schema->resultset('Artist')->all_async;   # deliberately unbound
    return $outside->then(sub { return Future->done(scalar @_) });
  });

  is scalar(settle($f)->get), 2, 'the unbound all_async resolves too';

  my ($select) = wire_for($backend, qr/^SELECT/);
  ok $select, 'the unbound resultset issued its SELECT';
  isnt $select->{conn}, $ctx->txn_conn->{id},
    'an UNBOUND resultset ran on a different, POOLED connection -- outside the '
    . 'transaction it appears to be inside, which is exactly why with_context '
    . 'exists';
  is scalar @{ $backend->pool->{_connections} }, 2,
    'and the pool had to spawn a second connection to serve it';
}

# ---------------------------------------------------------------------------
# 3. A Row derived from a bound resultset carries the context with it, so a
#    write-back lands on the pinned connection too. The chain
#    with_context -> first_async -> update_async is the one core's ADR 0045
#    calls out; here it runs over the real pool, where a stray pooled write
#    would be a write committed outside the transaction that produced it.
# ---------------------------------------------------------------------------

{
  my ($schema, $backend) = wired();
  $backend->{rows} = [ $ARTISTS[0] ];

  my ($ctx);
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    return $schema->resultset('Artist')
                  ->with_context($ctx)
                  ->first_async
                  ->then(sub {
                      my $row = shift;
                      return $row->update_async({ name => 'Miles Dewey Davis' });
                    });
  });

  ok !settle($f)->is_failed, 'the bound row write-back completed'
    or diag scalar $f->failure;

  my ($update) = wire_for($backend, qr/^UPDATE/);
  ok $update, 'the row issued an UPDATE';
  is $update->{conn}, $ctx->txn_conn->{id},
    'a row derived from a bound resultset writes back on the PINNED connection';
  is scalar @{ $backend->pool->{_connections} }, 1,
    'no second connection was needed, so nothing escaped the transaction';
}

# ---------------------------------------------------------------------------
# 4. The gate itself: core admits a context by asking whether it is a blessed
#    thing that can select_async. This transport's context has to satisfy that
#    -- it is the one contract with_context places on a transport at all, and
#    a driver adapter that swapped in a context class of its own would have to
#    keep satisfying it.
# ---------------------------------------------------------------------------

{
  my ($schema, $backend) = wired();
  my $rs = $schema->resultset('Artist');

  my $ctx = DBIO::Async::TransactionContext->new(
    storage => $backend,
    $backend->_txn_conn_accessor => { id => 99 },
  );

  ok( DBIO::Async::TransactionContext->can('select_async'),
    'this dist\'s transaction context can select_async -- the predicate core '
    . 'admits a context by' );
  lives_ok { $rs->with_context($ctx) }
    'and with_context accepts it';
  is $rs->with_context($ctx)->_async_context, $ctx,
    '... binding that very context to the clone';

  throws_ok { $rs->with_context('not a context') }
    qr/with_context requires an async context object/,
    'while a non-context is refused, loudly';
}

done_testing;

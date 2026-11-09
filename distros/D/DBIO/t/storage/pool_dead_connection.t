use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k230. DBIO::Storage::PoolBase had no way to learn that a connection had
# died. Its only health signal is the readiness Future, and that resolved once,
# when the connection first came up: a connection whose server session was
# gone afterwards went back to the idle list on release and was handed out
# again, to fail the next caller's query too -- and in a pool of one, every
# caller's, for good.
#
# The seam this file pins is _mark_connection_dead: whoever sees the death --
# the transport's executor, on a connection-level error -- reports it, and the
# pool never hands that connection out again. The claims:
#
#   * a connection reported dead while checked out is retired when it comes
#     back through release: closed once, no longer counted, not idled -- and
#     the next acquire gets a fresh connection;
#   * a caller already queued for its slot gets a fresh connection, not the
#     dead one;
#   * a connection reported dead while idle is retired at once;
#   * a report about a connection the pool does not hold, or after shutdown,
#     changes nothing;
#   * a healthy connection's release is unchanged;
#   * end to end: a transport that reports the death from its query path gets
#     the caller's next query onto a fresh connection.

{
  package K230::Conn;
  sub new { bless { id => $_[1], alive => 1 }, $_[0] }
}

{
  package K230::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K230::Conn->new(++$_[0]->{_next_id}) }

  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }
}

sub new_pool {
  my ($size) = @_;
  return K230::Pool->new(
    conninfo     => 'fake',
    size         => $size // 1,
    future_class => 'DBIO::Test::Future',
  );
}

# ---------------------------------------------------------------------------
# Reported dead while checked out. Asserts: the report alone closes nothing
# (the caller still holds the connection); the release then retires it --
# closed once, no longer counted, not idle; the next acquire resolves on a
# fresh connection, never the dead one.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  $pool->_mark_connection_dead($conn);
  is_deeply $pool->{closed} // [], [],
    'checked out: the report closes nothing while the caller holds it';

  $pool->release($conn);
  is_deeply $pool->{closed} // [], [ 1 ], 'checked out: release retires it, closed once';
  is $pool->size, 0, 'checked out: the pool no longer counts it';
  is $pool->available, 0, 'checked out: it is not idled';

  my $next = $pool->acquire;
  ok $next->is_ready, 'checked out: the next acquire resolves';
  is $next->is_ready && $next->get->{id}, 2,
    'checked out: on a fresh connection, never the dead one';
}

# ---------------------------------------------------------------------------
# A caller is queued for the pool's one connection when it is reported dead.
# Asserts: the release hands the queued caller a fresh connection, not the
# dead one, and the pool counts that one only.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'queued caller: pending while the connection is out';

  $pool->_mark_connection_dead($conn);
  $pool->release($conn);
  is_deeply $pool->{closed} // [], [ 1 ], 'queued caller: the dead connection is retired';
  ok $waiter->is_ready, 'queued caller: resolves on the release';
  is $waiter->is_ready && $waiter->get->{id}, 2,
    'queued caller: on a fresh connection, not the dead one';
  is $pool->size, 1, 'queued caller: the pool counts the fresh connection only';
}

# ---------------------------------------------------------------------------
# Reported dead while idle -- a transport's error callback can fire for a
# connection nobody holds. Asserts: it is retired at once, and the next
# acquire spawns a fresh connection instead of taking it from the idle list.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  is $pool->available, 1, 'idle: the connection is idle';

  $pool->_mark_connection_dead($conn);
  is_deeply $pool->{closed} // [], [ 1 ], 'idle: the report retires it at once';
  is $pool->available, 0, 'idle: it left the idle list';
  is $pool->size, 0, 'idle: the pool no longer counts it';
  my $next = $pool->acquire;
  is $next->is_ready && $next->get->{id}, 2, 'idle: the next acquire gets a fresh one';
}

# ---------------------------------------------------------------------------
# Reports that change nothing. Asserts: a second report and a report about a
# connection already retired close nothing more; after shutdown a report closes
# nothing a second time; a report about undef is ignored.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  $pool->_mark_connection_dead($conn);
  $pool->_mark_connection_dead($conn);
  $pool->release($conn);
  $pool->_mark_connection_dead($conn);
  $pool->release($conn);
  is_deeply $pool->{closed}, [ 1 ],
    'repeated reports and releases retire the connection once';

  my $other = new_pool(1);
  my $held = $other->acquire->get;
  $other->shutdown;
  $other->_mark_connection_dead($held);
  is_deeply $other->{closed}, [ 1 ], 'after shutdown: a report closes nothing again';

  my $lived = eval { new_pool(1)->_mark_connection_dead(undef); 1 };
  ok $lived, 'a report about undef is ignored';
}

# ---------------------------------------------------------------------------
# A mark must not outlive its connection. The pool can drop a connection
# without retiring it -- a forked child dropping what it inherited
# (_verify_pid, emulated here by an owner pid that is not ours) -- and a later
# connection may then reuse the dropped one's address. Asserts: once the
# marked connection is gone, no mark is left, and the connection spawned after
# it is released to the idle list like any healthy one, closing nothing.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  $pool->_mark_connection_dead($conn);
  $pool->{_owner_pid} = $$ + 1;   # as seen from a forked child
  undef $conn;

  my $fresh = $pool->acquire->get;
  is $fresh->{id}, 2, 'dropped marked connection: the next acquire spawns a fresh one';
  ok !grep({ defined } values %{ $pool->{_dead} || {} }),
    'dropped marked connection: its mark went with it';
  $pool->release($fresh);
  is $pool->available, 1, 'dropped marked connection: the fresh one is idled on release';
  is_deeply $pool->{closed} // [], [], 'dropped marked connection: nothing was closed';
}

# ---------------------------------------------------------------------------
# The claim the seam must not cost: a connection nobody reported goes back to
# the idle list and is handed out again.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(1);
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  is_deeply $pool->{closed} // [], [], 'healthy: nothing is closed';
  is $pool->acquire->get->{id}, 1, 'healthy: the same connection is reused';
}

# ---------------------------------------------------------------------------
# End to end through a transport, the way a driver uses the seam. The fake
# transport runs every query on a pooled connection and releases it when the
# query settles; a query on a connection whose server session is gone fails
# with "server has gone away", and the transport reports that as the
# connection's death. Asserts: the first query after the session died fails
# with that error; the next query runs -- and succeeds -- on a fresh
# connection; the dead one was closed once.
# ---------------------------------------------------------------------------
{
  package K230::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool { $_[0]->{pool} ||= main::new_pool(1) }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      push @{ $self->{ran_on} }, $conn->{id};
      my $f = $conn->{alive}
        ? $self->future_class->done([ $conn->{id} ])
        : $self->future_class->fail("server has gone away\n");
      $self->pool->_mark_connection_dead($conn) unless $conn->{alive};
      $self->pool->release($conn);
      return $f;
    });
  }
}

{
  my $backend = K230::Backend->new(DBIO::Test->init_schema);
  my $pool = $backend->pool;

  my $first = $backend->_query_async('SELECT 1', []);
  is_deeply [ $first->get ], [ [ 1 ] ], 'transport: the first query runs on connection 1';

  $pool->{_connections}[0]{alive} = 0;   # the server drops the session
  my $failed = $backend->_query_async('SELECT 1', []);
  ok $failed->is_failed, 'transport: the query on the dead session fails';
  like eval { $failed->get; 1 } ? '' : "$@", qr/server has gone away/,
    'transport: ... with the connection error';

  my $next = $backend->_query_async('SELECT 1', []);
  ok $next->is_ready && !$next->is_failed, 'transport: the next query succeeds';
  is_deeply $backend->{ran_on}, [ 1, 1, 2 ],
    'transport: ... on a fresh connection, not the dead one';
  is_deeply $pool->{closed}, [ 1 ], 'transport: the dead connection was closed once';
}

done_testing;

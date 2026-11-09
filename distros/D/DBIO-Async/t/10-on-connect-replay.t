use strict;
use warnings;
use Test::More;
use Test::Exception;

use Future;
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Storage::DBI;      # the OWNING sync storage whose actions get replayed
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for the `on_connect_replay` transport capability at THIS dist's
# layer. No DB, no event loop, no DBD -- the mock transport is the whole
# backend and its "connection" is a { dbh => $fake } wrapper that only records
# statements.
#
# WHY THIS EXISTS AT ALL (core k68): a pooled async connection is a SECOND
# physical session to the same server. Whatever the user configured on the sync
# storage -- on_connect_do => ['SET search_path ...'], a connect_call_* that
# sets a timezone or LOADs an extension -- shapes every sync query but would
# silently NOT apply to *_async unless the pool replays it per connection. The
# failure mode is the nasty kind: no error, just a query answered against the
# wrong search_path/timezone by whichever connection the pool happened to hand
# out. DBIO::Async::Storage->transport_capabilities therefore ADVERTISES
# `on_connect_replay` to core's composition gate
# (DBIO::Storage::DBI::_async_storage refuses to compose an async layer whose
# required_transport_capabilities this transport does not provide). This file
# holds that advertisement to its promise.
#
# WHAT ONLY THIS LAYER CAN SHOW. The dispatch itself is core's
# (DBIO::Storage::Async::_setup_pool_connection ->
# DBIO::Storage::DBI::_run_pool_connect_actions -> the runner ->
# DBIO::Storage::Async::_run_pool_connect_statement), and the driver dists test
# their own connection shapes (dbio-postgresql-ev t/07 + t/23, dbio-mysql-ev
# t/07 + t/14). In between sits exactly what is asserted here: that
# DBIO::Async::Storage::pool builds its DBIO::Async::Pool WITH the `storage`
# back-reference the core spawn hook needs, that the future_io
# { dbh => $dbh } connection shape really is served by the inherited runner,
# and that the replay lands on every freshly spawned connection BEFORE any
# caller can query it. Drop the back-reference and nothing errors -- the replay
# just never happens again, which is precisely why it needs a test here.

# --- ReplayDbh10: a do-capable handle that only records ---------------------

{
  package ReplayDbh10;
  sub new { bless { log => [], fail_on => $_[1] }, $_[0] }
  # $dbh->do($sql, \%attrs, @bind) -- the shape core's
  # _run_pool_connect_statement drives.
  sub do {
    my ($self, $sql, $attrs, @bind) = @_;
    push @{ $self->{log} }, [ $sql, @bind ];
    die "connect action refused: $sql\n"
      if $self->{fail_on} && $sql =~ $self->{fail_on};
    return 1;
  }
  # SQL only, for the readable is_deeply diffs below
  sub sql { [ map { $_->[0] } @{ $_[0]->{log} } ] }
}

# --- SyncOwner10: the real sync storage that owns the async backend ---------
#
# A genuine DBIO::Storage::DBI (never connected -- the DSN below is a
# placeholder string, this dist must work with no DBD installed), so the replay
# runs through the SAME connection-action dispatch the sync path uses:
# on_connect_call resolved as connect_call_* METHODS ON THIS CLASS, then
# on_connect_do parsed into do_sql actions. The connect_call_* below exists to
# prove that resolution happens on the owner, not on the async transport --
# the async transport has never heard of `set_session`.

{
  package SyncOwner10;
  use base 'DBIO::Storage::DBI';

  sub connect_call_set_session {
    my ($self, $value) = @_;
    # _do_query is the sync emitter; inside a replay it is redirected onto the
    # pool connection instead of this storage's dbh. Bound, to prove bind
    # values survive the redirection.
    $self->_do_query([ 'SELECT set_config(?, ?)', undef, 'myapp.mode', $value ]);
  }
}

# --- TestStorage10: the future_io-shaped mock transport ---------------------

{
  package TestStorage10;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _normalize_conninfo       { $_[1] }
  sub _conn_ready               { 1 }
  sub _shutdown_pool_connection { }
  sub _txn_context_class        { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor        { 'txn_conn' }

  # The future_io connection shape: a { dbh => $dbh } wrapper, which
  # DBIO::Async::Storage's POD promises the inherited
  # _run_pool_connect_statement handles without a driver override.
  sub _create_pool_connection {
    my $self = shift;
    return { dbh => ReplayDbh10->new($self->{_fail_on}) };
  }

  # Short-circuit the wire, but record the session state the connection had AT
  # QUERY TIME. That snapshot is the whole point: it is what a caller's first
  # query actually sees.
  sub _await_query_result {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{_seen} }, { sql => $sql, setup => [ @{ $conn->{dbh}->sql } ] };
    return Future->done([ 1 ]);
  }
}

# Build an owner + transport pair wired the way
# DBIO::Storage::DBI::_async_storage wires them: the async backend gets the
# sync storage's connect info and a weak back-reference to it.
sub new_pair {
  my (%args) = @_;

  my $sync = SyncOwner10->new(undef);
  $sync->connect_info([
    'dbi:Mock:replaytest', '', '',
    {
      # Only the keys a test actually sets -- an absent key must mean
      # "nothing to replay", which section 6 relies on.
      ( exists $args{on_connect_do}    ? (on_connect_do    => $args{on_connect_do})    : () ),
      ( exists $args{on_connect_call}  ? (on_connect_call  => $args{on_connect_call})  : () ),
      ( exists $args{on_disconnect_do} ? (on_disconnect_do => $args{on_disconnect_do}) : () ),
    },
  ]);

  my $async = TestStorage10->new(undef);
  $async->{_fail_on} = $args{fail_on};
  $async->{_seen}    = [];
  $async->connect_info([{ host => 'localhost', pool_size => $args{pool_size} || 2 }]);
  $async->_owner_storage($sync);

  # The owner is held WEAKLY; hand it back so the caller keeps it alive.
  return ($sync, $async);
}

# ---------------------------------------------------------------------------
# 1. The capability is advertised -- as a CLASS method, and inherited.
#    Core's gate calls $backend_class->transport_capabilities on the resolved
#    class, before any instance exists, and a driver adapter that adds nothing
#    of its own must still advertise what its base really does.
# ---------------------------------------------------------------------------

{
  my %caps = map { $_ => 1 } DBIO::Async::Storage->transport_capabilities;
  ok $caps{on_connect_replay},
    'DBIO::Async::Storage advertises the on_connect_replay transport capability';

  my %sub_caps = map { $_ => 1 } TestStorage10->transport_capabilities;
  ok $sub_caps{on_connect_replay},
    'a driver adapter inherits the advertisement without redeclaring it';
}

# ---------------------------------------------------------------------------
# 2. The wiring the advertisement rests on: the pool carries the storage
#    back-reference. DBIO::Storage::PoolBase::_spawn_connection reaches
#    _setup_pool_connection ONLY through {storage}; without it every assertion
#    below would still "pass" as a silent no-replay.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(on_connect_do => ['SET a = 1']);

  my $pool = $async->pool;
  isa_ok $pool, 'DBIO::Async::Pool', 'the skeleton builds';
  is $pool->{storage}, $async,
    'pool is built with the storage back-reference core needs to reach _setup_pool_connection';
  can_ok $async, '_setup_pool_connection', '_run_pool_connect_statement';
}

# ---------------------------------------------------------------------------
# 3. A freshly spawned connection is replayed: on_connect_call first, then
#    on_connect_do in the configured order, with bind values intact -- the
#    same order and dispatch the sync path uses, on the pool connection.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(
    on_connect_call => [ [ set_session => 'batch' ] ],
    on_connect_do   => [ 'SET search_path = myschema', 'SET timezone = UTC' ],
  );

  my $conn = $async->pool->acquire->get;

  is_deeply $conn->{dbh}->sql,
    [
      'SELECT set_config(?, ?)',        # on_connect_call -> connect_call_set_session
      'SET search_path = myschema',     # on_connect_do, in order
      'SET timezone = UTC',
    ],
    'every configured connect action was replayed on the pooled connection, in order';

  is_deeply $conn->{dbh}{log}[0], [ 'SELECT set_config(?, ?)', 'myapp.mode', 'batch' ],
    'bind values survive the redirection onto the pool connection';

  # The connect_call_* resolved on the OWNER: the transport does not have it.
  ok $sync->can('connect_call_set_session'), 'connect_call_* lives on the owning sync storage';
  ok !$async->can('connect_call_set_session'),
    'and the async transport never defines it -- resolution really happened on the owner';
}

# ---------------------------------------------------------------------------
# 4. EVERY physical connection, not just the first -- and exactly once each.
#    A pool is a set of independent sessions; the second one is as wrong for
#    its next user as the first would be. Idle reuse is not a new session and
#    must not replay again.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(
    on_connect_do => [ 'SET search_path = myschema' ],
    pool_size     => 2,
  );

  # Hold the first, so the second acquire has to SPAWN rather than reuse.
  my $c1 = $async->pool->acquire->get;
  my $c2 = $async->pool->acquire->get;

  isnt $c1, $c2, 'two concurrent acquires yield two distinct physical connections';
  is_deeply $c1->{dbh}->sql, [ 'SET search_path = myschema' ],
    'first spawned connection replayed the session setup';
  is_deeply $c2->{dbh}->sql, [ 'SET search_path = myschema' ],
    'second spawned connection replayed it too -- not only the first';

  # Idle reuse: same physical session, so no second replay.
  $async->pool->release($c1);
  my $again = $async->pool->acquire->get;
  is $again, $c1, 'the idle connection is handed back out';
  is_deeply $again->{dbh}->sql, [ 'SET search_path = myschema' ],
    'reusing an idle connection does not replay the setup a second time';
}

# ---------------------------------------------------------------------------
# 5. The point of all of it: the FIRST query on a fresh pooled connection
#    already runs inside the configured session. Asserted from the query
#    seam's own view of the connection, so a replay that got deferred until
#    after the connection was handed out would fail here even though the
#    counts in section 3 still matched.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(
    on_connect_do => [ 'SET search_path = myschema' ],
    pool_size     => 1,
  );

  $async->select_async('artist', ['*'], { id => 1 })->get;

  is scalar @{ $async->{_seen} }, 1, 'the query reached the transport seam';
  is_deeply $async->{_seen}[0]{setup}, [ 'SET search_path = myschema' ],
    'the very first query saw a connection whose session setup was ALREADY applied';
  like $async->{_seen}[0]{sql}, qr/FROM artist/, 'and it was the caller\'s query';
}

# ---------------------------------------------------------------------------
# 6. Nothing configured -> nothing replayed. Guards the other direction: a
#    replay path that invented statements (or ran a stale/last-known action
#    list) would be just as wrong as one that ran none.
# ---------------------------------------------------------------------------

{
  # $sync must stay in scope: the owner is held weakly, and letting it go would
  # turn this into section 7's un-owned case instead of "owned, but empty".
  my ($sync, $async) = new_pair(pool_size => 1);
  my $conn = $async->pool->acquire->get;
  is_deeply $conn->{dbh}->sql, [],
    'a storage with no on_connect_* actions runs no statements on a fresh connection';
}

# ---------------------------------------------------------------------------
# 7. No owner wired at all (a standalone async storage, no embedding sync
#    storage) -- the seam is a documented no-op, not a crash. This is the
#    shape every offline test in this dist uses, so a regression here would
#    take the whole suite with it.
# ---------------------------------------------------------------------------

{
  my $async = TestStorage10->new(undef);
  $async->{_seen} = [];
  $async->connect_info([{ host => 'localhost', pool_size => 1 }]);

  ok !$async->_owner_storage, 'no owning sync storage';
  my $conn;
  lives_ok { $conn = $async->pool->acquire->get }
    'an un-owned pool spawns connections without attempting a replay';
  is_deeply $conn->{dbh}->sql, [], 'and runs no connect statements';
}

# ---------------------------------------------------------------------------
# 8. A refused connect action fails LOUD -- as a FAILED FUTURE, on both
#    entry points (core k109). Spawn is synchronous inside
#    DBIO::Storage::PoolBase::_acquire_slot, so this used to be the one path
#    on a Future-based API that threw instead of failing, and the ->on_fail a
#    caller is taught to write could never see it. It now rides the Future
#    like every other failure here, with ->get rethrowing it verbatim for
#    anyone who wants it as an exception. What has never changed, and is what
#    actually matters: nothing hands the caller a connection that skipped its
#    session setup.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(
    on_connect_do => [ 'SET search_path = myschema' ],
    fail_on       => qr/search_path/,
    pool_size     => 1,
  );

  my $af = $async->pool->acquire;
  ok $af->is_failed,
    'a failing connect action fails the acquire Future (no silent skip)';
  like scalar $af->failure, qr/connect action refused: SET search_path = myschema/,
    'and the refusal is carried verbatim';
  throws_ok { $af->get } qr/connect action refused: SET search_path = myschema/,
    'a caller who wants it as an exception gets it from ->get';

  is $async->pool->available, 0,
    'the half-configured connection was never put into the idle pool';

  # The other half of core k109: the refused connection is RETIRED, not
  # merely withheld. It used to stay registered -- never handed out, never
  # released, never reused -- so a pool that keeps being refused filled up
  # with connections that do not exist until acquire() only ever returned
  # pending waiters. Core asserts this against its mock pool; this is the only
  # place it can be asserted against the real one.
  is $async->pool->size, 0,
    'and it does not stay counted against the pool -- no leaked slot';
}

{
  my ($sync, $async) = new_pair(
    on_connect_do => [ 'SET search_path = myschema' ],
    fail_on       => qr/search_path/,
    pool_size     => 1,
  );

  my $sf = $async->select_async('artist', ['*'], {});
  ok $sf->is_failed,
    'select_async on a storage whose connect action fails returns a failed Future';
  like scalar $sf->failure, qr/connect action refused/,
    'carrying the refusal, so ->on_fail sees it instead of an eval having to';

  is scalar @{ $async->{_seen} }, 0,
    'and no query was ever sent on the unconfigured connection';
}

# ---------------------------------------------------------------------------
# 9. The symmetric half of the same capability: on_disconnect_do runs against
#    the connection while it is still live, at pool shutdown. Advertised in
#    the same breath as the connect replay, so it is held to the same standard.
# ---------------------------------------------------------------------------

{
  my ($sync, $async) = new_pair(
    on_connect_do    => [ 'SET search_path = myschema' ],
    on_disconnect_do => 'SELECT pg_advisory_unlock_all()',
    pool_size        => 1,
  );

  my $conn = $async->pool->acquire->get;
  is_deeply $conn->{dbh}->sql, [ 'SET search_path = myschema' ],
    'connect action replayed before shutdown';

  $async->pool->shutdown;
  is_deeply $conn->{dbh}->sql,
    [ 'SET search_path = myschema', 'SELECT pg_advisory_unlock_all()' ],
    'on_disconnect_do ran on the connection at shutdown, while it was still live';
}

done_testing;

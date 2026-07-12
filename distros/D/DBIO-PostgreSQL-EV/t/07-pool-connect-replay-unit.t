use strict;
use warnings;
use Test::More;
use Test::Exception;

# OFFLINE unit test for the karr #22 WP3 / karr #68 pool-connect replay WIRING.
# No real DB. The live end-to-end assertion is t/23; here we lock down the pure
# structure that makes replay possible, so a regression that unwires it fails
# offline immediately:
#
#   1. the EV pool is created with a `storage => $self` back-reference, so the
#      core PoolBase spawn path can reach _setup_pool_connection (without this
#      back-ref the replay silently never fires -- the #69 facet-1 bug);
#   2. _run_pool_connect_statement drives a statement on the EV::Pg connection
#      shape (query for bindless, query_params with '?'->'$N' shaping for bound),
#      and fails loud on a statement error;
#   3. the whole replay dispatch (_setup_pool_connection -> owner
#      _run_pool_connect_actions -> the runner) reaches our seam and executes on
#      the freshly-spawned connection.
#
# Everything resolves synchronously here (the fake connection reports connected
# and fires its query callbacks inline), so no EV loop actually runs.

use Future;
use DBIO::PostgreSQL::EV::Storage;

# --- Fakes --------------------------------------------------------------------

# A minimal EV::Pg stand-in: reports connected, records every dispatched SQL and
# its bind, and fires the query callback synchronously. $fail lets a test drive
# the error path.
{
  package FakeConn07;
  sub new { bless { queries => [], params => [], fail => undef }, shift }
  sub is_connected { 1 }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    $cb->(undef, $self->{fail}) if $cb;
  }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    push @{ $self->{params} }, $bind;
    $cb->(undef, $self->{fail}) if $cb;
  }
}

# A pool stand-in WITHOUT _connection_ready_future (not a PoolBase subclass at
# all), so _run_pool_connect_statement takes the is_connected fallback branch
# (the fake reports connected -> the wait is a no-op).
{
  package FakePool07;
  sub new { bless {}, shift }
  sub shutdown {}   # storage DESTROY -> disconnect -> pool->shutdown
}

# --- 1. the pool is wired with the storage back-reference ---------------------

{
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'localhost', dbname => 'test' } ]);

  my $pool = $storage->pool;
  isa_ok $pool, 'DBIO::PostgreSQL::EV::Pool', 'pool is the EV pool';
  is $pool->{storage}, $storage,
    'pool carries the storage back-reference (karr #68 replay can reach _setup_pool_connection)';
}

# --- 2. _run_pool_connect_statement drives the EV::Pg connection --------------

{
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool07->new;   # no _connection_ready_future -> is_connected path
  my $conn = FakeConn07->new;

  # bindless connect statement -> query()
  $storage->_run_pool_connect_statement($conn, q{SET search_path = myschema}, undef);
  is_deeply $conn->{queries}, [ 'SET search_path = myschema' ],
    'bindless statement dispatched via query() on the connection';
  is_deeply $conn->{params}, [], 'no query_params used for a bindless statement';

  # bound connect statement -> query_params() with '?' shaped to '$N'
  $storage->_run_pool_connect_statement($conn, q{SELECT set_config('x', ?, false)}, undef, 'v');
  is $conn->{queries}[-1], q{SELECT set_config('x', $1, false)},
    'bound statement shaped ? -> $1 before dispatch (query_params)';
  is_deeply $conn->{params}[-1], [ 'v' ], 'bind value forwarded to query_params';
}

# --- 2b. a failing connect statement fails loud -------------------------------

{
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool07->new;
  my $conn = FakeConn07->new;
  $conn->{fail} = 'permission denied for schema';

  throws_ok {
    $storage->_run_pool_connect_statement($conn, q{SET search_path = nope}, undef)
  } qr/pool connect statement failed: permission denied/,
    'a statement error croaks (fail loud, no silent drop)';
}

# --- 3. full replay dispatch reaches the seam ---------------------------------
# Wire a fake OWNER whose _run_pool_connect_actions replays two actions; assert
# both land on the freshly-spawned connection through our seam.

{
  package FakeOwner07;
  sub new { bless {}, shift }
  # Mirror the core owner contract: hand the runner one ($sql, $attrs, @bind)
  # per action. Here: one on_connect_do-style and one on_connect_call-style.
  sub _run_pool_connect_actions {
    my ($self, $runner) = @_;
    $runner->(q{SET myapp.a = 'do'},   undef);
    $runner->(q{SET myapp.b = 'call'}, undef);
    return $self;
  }
}

{
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool07->new;
  my $owner = FakeOwner07->new;
  $storage->_owner_storage($owner);   # held strongly by $owner lexical below

  my $conn = FakeConn07->new;
  $storage->_setup_pool_connection($conn);

  is_deeply $conn->{queries},
    [ q{SET myapp.a = 'do'}, q{SET myapp.b = 'call'} ],
    'both replayed actions executed on the freshly-spawned connection via the seam';

  # keep $owner alive to the end (the storage holds _owner_storage weakly)
  ok $owner, 'owner kept in scope';
}

done_testing;

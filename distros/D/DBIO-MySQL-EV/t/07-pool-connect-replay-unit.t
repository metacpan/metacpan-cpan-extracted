use strict;
use warnings;
use Test::More;
use Test::Exception;

# OFFLINE unit test for the karr #19 WP3 / karr #18 / core #68 pool-connect
# replay WIRING. No real DB, no event loop actually runs. The live end-to-end
# assertion is t/14; here we lock down the pure structure that makes replay
# possible, so a regression that unwires it fails offline immediately:
#
#   1. the EV pool is created with a `storage => $self` back-reference, so the
#      core PoolBase spawn path can reach _setup_pool_connection (without this
#      back-ref the replay silently never fires -- the karr #18 facet-1 bug);
#   2. _run_pool_connect_statement drives a statement on the EV::MariaDB
#      connection shape (query for bindless, prepare+execute for bound), with
#      '?' placeholders LEFT UNTOUCHED (MySQL native -- _transform_sql identity),
#      and fails loud on a statement error;
#   3. the whole replay dispatch (_setup_pool_connection -> owner
#      _run_pool_connect_actions -> the runner) reaches our seam and executes on
#      the freshly-spawned connection.
#
# Everything resolves synchronously here (the fake connection reports connected
# and fires its callbacks inline), so no EV loop actually runs.

use DBIO::MySQL::EV::Storage;

# --- Fakes --------------------------------------------------------------------

# A minimal EV::MariaDB stand-in: reports connected, records every dispatched
# SQL and its bind, and fires the callback synchronously. $fail lets a test
# drive the error path.
{
  package FakeConn07;
  sub new { bless { queries => [], params => [], fail => undef }, shift }
  sub is_connected { 1 }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    $cb->(undef, $self->{fail}) if $cb;
  }
  # EV::MariaDB->query() takes no binds; a bound statement goes prepare+execute.
  sub prepare {
    my ($self, $sql, $cb) = @_;
    $cb->(bless({ sql => $sql }, 'FakeStmt07'), undef) if $cb;
  }
  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    push @{ $self->{queries} }, $stmt->{sql};
    push @{ $self->{params} }, $bind;
    $cb->(undef, $self->{fail}) if $cb;
  }
}

# --- 1. the pool is wired with the storage back-reference ---------------------

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'localhost', database => 'test' } ]);

  my $pool = $storage->pool;
  isa_ok $pool, 'DBIO::MySQL::EV::Pool', 'pool is the EV pool';
  is $pool->{storage}, $storage,
    'pool carries the storage back-reference (karr #18 replay can reach _setup_pool_connection)';
}

# --- 2. _run_pool_connect_statement drives the EV::MariaDB connection ----------

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $conn = FakeConn07->new;

  # bindless connect statement -> query()
  $storage->_run_pool_connect_statement($conn, q{SET time_zone = '+00:00'}, undef);
  is_deeply $conn->{queries}, [ q{SET time_zone = '+00:00'} ],
    'bindless statement dispatched via query() on the connection';
  is_deeply $conn->{params}, [], 'no prepare/execute binds for a bindless statement';

  # bound connect statement -> prepare + execute with '?' LEFT AS '?' (native)
  $storage->_run_pool_connect_statement($conn, q{SELECT set_myvar(?)}, undef, 'v');
  is $conn->{queries}[-1], q{SELECT set_myvar(?)},
    'bound statement keeps its ? placeholder (MySQL native -- no ?->$N rewrite)';
  is_deeply $conn->{params}[-1], [ 'v' ], 'bind value forwarded to execute()';
}

# --- 2b. a failing connect statement fails loud -------------------------------

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $conn = FakeConn07->new;
  $conn->{fail} = 'Access denied for user';

  throws_ok {
    $storage->_run_pool_connect_statement($conn, q{SET sql_mode = 'STRICT'}, undef)
  } qr/pool connect statement failed: Access denied/,
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
    $runner->(q{SET time_zone = '+00:00'}, undef);
    $runner->(q{SET sql_mode = 'TRADITIONAL'}, undef);
    return $self;
  }
}

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $owner = FakeOwner07->new;
  $storage->_owner_storage($owner);   # held strongly by $owner lexical below

  my $conn = FakeConn07->new;
  $storage->_setup_pool_connection($conn);

  is_deeply $conn->{queries},
    [ q{SET time_zone = '+00:00'}, q{SET sql_mode = 'TRADITIONAL'} ],
    'both replayed actions executed on the freshly-spawned connection via the seam';

  # keep $owner alive to the end (the storage holds _owner_storage weakly)
  ok $owner, 'owner kept in scope';
}

done_testing;

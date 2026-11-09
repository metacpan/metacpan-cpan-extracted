use strict;
use warnings;
use Test::More;
use Test::Exception;

# OFFLINE unit test for the karr #19 WP3 / karr #18 / core #68 pool-connect
# replay WIRING. No real DB, no real connection. The live end-to-end
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
#      the freshly-spawned connection;
#   4. the runner waits on the POOL's per-connection readiness Future before it
#      dispatches anything -- so a spawn whose connect fails throws that connect
#      error, instead of busy-spinning on an is_connected that never turns true
#      (k29; the ingredient was already there, the runner just ignored it).
#
# Sections 1-3 resolve synchronously (the fake connection reports connected and
# fires its callbacks inline), so no EV loop actually runs there. Section 4 does
# drive real EV ticks and is wall-clock guarded, so a regression of the spin bug
# fails the suite instead of hanging it.

use Future;
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
    $cb->($self->{rows}, $self->{fail}) if $cb;
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
    $cb->($self->{rows}, $self->{fail}) if $cb;
  }
  # Records what was closed: a prepared statement the server keeps until the
  # connection closes is a leak (karr k45).
  sub close_stmt {
    my ($self, $stmt, $cb) = @_;
    push @{ $self->{closed} }, $stmt->{sql};
    $cb->(1) if $cb;
  }
}

# A connection that never comes up: is_connected stays false forever, exactly
# like an EV::MariaDB handle whose spawn was refused. Used by section 4.
{
  package DeadConn07;
  our @ISA = ('FakeConn07');
  sub is_connected { 0 }
}

# A connection that comes up on a LATER tick and records the order in which
# things happened, so section 4 can assert the runner dispatched AFTER
# readiness, not before it.
{
  package LateConn07;
  sub new {
    my ($class, $trace) = @_;
    return bless { trace => $trace, queries => [], connected => 0 }, $class;
  }
  sub is_connected { $_[0]{connected} }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{queries} }, $sql;
    push @{ $self->{trace} }, 'query';
    $cb->(undef, undef) if $cb;
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

# A pool stand-in WITH the readiness seam, handing out a caller-supplied Future.
{
  package ReadyPool07;
  sub new { my ($class, $ready) = @_; bless { ready => $ready }, $class }
  sub _connection_ready_future { $_[0]{ready} }
  sub shutdown {}
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
  $storage->{pool} = FakePool07->new;   # no readiness seam -> is_connected path
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
  is_deeply $conn->{closed}, [ q{SELECT set_myvar(?)} ],
    'the prepared connect statement is closed again, the bindless one had none (karr k45)';
}

# --- 2a. dbio_rows: the rows of the statement come back (karr k99) -----------
#
# Core's connect_call_* reads (DBIO::Storage::DBI::_pool_connect_rows) ask the
# runner for the rows of a query with { dbio_rows => 1 } and expect an array
# reference of row array references. Without the key nothing is returned.

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool07->new;
  my $conn = FakeConn07->new;
  $conn->{rows} = [ [ 1, 'a' ], [ 2, 'b' ] ];

  is_deeply $storage->_run_pool_connect_statement($conn, q{SELECT id, name FROM t}, { dbio_rows => 1 }),
    [ [ 1, 'a' ], [ 2, 'b' ] ],
    'dbio_rows on a bindless statement returns the rows as an array reference of rows';

  is_deeply $storage->_run_pool_connect_statement($conn, q{SELECT id, name FROM t WHERE id > ?}, { dbio_rows => 1 }, 0),
    [ [ 1, 'a' ], [ 2, 'b' ] ],
    'dbio_rows on a bound statement returns the rows too';

  $conn->{rows} = [];
  is_deeply $storage->_run_pool_connect_statement($conn, q{SELECT 1 WHERE 0}, { dbio_rows => 1 }),
    [], 'dbio_rows on an empty result returns an empty array reference';

  $conn->{rows} = [ [ 1, 'a' ] ];
  is_deeply [ $storage->_run_pool_connect_statement($conn, q{SELECT 1}, {}) ], [],
    'without dbio_rows nothing is returned';
}

# --- 2b. a failing connect statement fails loud -------------------------------

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool07->new;
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
  $storage->{pool} = FakePool07->new;
  my $owner = FakeOwner07->new;
  $storage->_owner_storage($owner);   # held strongly by $owner lexical below

  my $conn = FakeConn07->new;
  $storage->_setup_pool_connection($conn);

  is_deeply $conn->{queries},
    [ q{SET time_zone = '+00:00'}, q{SET sql_mode = 'TRADITIONAL'},
      q{SELECT @@character_set_client, @@collation_connection} ],
    'both replayed actions, then the read of character set and collation, executed on the freshly-spawned connection via the seam';

  # keep $owner alive to the end (the storage holds _owner_storage weakly)
  ok $owner, 'owner kept in scope';
}

# --- 4. the readiness gate: a refused connect throws, it does not spin (k29) ---
#
# The regression this pins: the runner used to wait with
#
#     EV::run(EV::RUN_ONCE()) until $conn->is_connected;
#
# so a spawn whose connect was refused (on_error fires, the handle never
# connects) left the replay runner turning the loop forever -- a wrong password
# wedged the process instead of reporting itself. It now waits on the pool's
# per-connection readiness Future (the _connection_ready_future seam -- since
# karr k33 core's PoolBase default, which DBIO::MySQL::EV::Pool opts into by
# building its connections through _create_ready_connection; karr k20), which
# is FAILED from on_error, and rethrows that failure.
#
# Both cases settle on a LATER EV tick (0s timer), the way a real EV::MariaDB
# handle does, so this exercises the WAIT and not merely a pre-settled Future.
# The alarm is the anti-hang guard: under the old loop the runner never returns,
# and a regression must fail the suite rather than hang it.

require EV;

# 4a. connect FAILS on a later tick -> the connect error is rethrown here and
#     nothing is dispatched on the dead connection.
{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $conn    = DeadConn07->new;
  my $ready   = Future->new;
  $storage->{pool} = ReadyPool07->new($ready);

  my $timer = EV::timer(0, 0, sub {
    $ready->fail(q{Can't connect to MySQL server on '127.0.0.1' (111)});
  });

  my $err;
  {
    local $SIG{ALRM} = sub { die "TIMEOUT: replay runner spun on a failed connect (k29)\n" };
    alarm 10;
    eval { $storage->_run_pool_connect_statement($conn, q{SET time_zone = '+00:00'}, undef) };
    $err = $@;
    alarm 0;
  }

  unlike $err, qr/^TIMEOUT/,
    'a refused connect TERMINATES the replay runner (no endless is_connected spin)';
  like $err, qr/Can't connect to MySQL server/,
    'the connect error itself is rethrown from the readiness Future';
  is_deeply $conn->{queries}, [],
    'no connect statement dispatched on a connection that never came up';
}

# 4b. connect SUCCEEDS on a later tick -> the runner waits for readiness first
#     and only then dispatches (the gate must not lose the wait).
{
  my @trace;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $conn    = LateConn07->new(\@trace);
  my $ready   = Future->new;
  $storage->{pool} = ReadyPool07->new($ready);

  my $timer = EV::timer(0, 0, sub {
    $conn->{connected} = 1;
    push @trace, 'ready';
    $ready->done($conn);
  });

  {
    local $SIG{ALRM} = sub { die "TIMEOUT: replay runner never saw readiness (k29)\n" };
    alarm 10;
    $storage->_run_pool_connect_statement($conn, q{SET sql_mode = 'TRADITIONAL'}, undef);
    alarm 0;
  }

  is_deeply \@trace, [ 'ready', 'query' ],
    'the statement is dispatched only after the readiness Future resolves';
  is_deeply $conn->{queries}, [ q{SET sql_mode = 'TRADITIONAL'} ],
    'the connect statement still runs on a connection that comes up late';
}

done_testing;

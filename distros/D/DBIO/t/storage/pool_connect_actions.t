use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr #68: a freshly-spawned async pool connection must replay the SAME
# on_connect_do / on_connect_call (and their on_disconnect_* counterparts) the
# owning sync storage was configured with, BEFORE it is served to any query --
# otherwise pooled async connections diverge silently from the sync path on the
# same instance (different search_path/timezone/SET/extension LOADs).
#
# This is a mock-only test: a recording pool (subclass of the core
# DBIO::Storage::PoolBase) whose connections record every statement run against
# them, a fake async backend (subclass of DBIO::Storage::Async, immediate
# transport), and an owning sync storage (subclass of DBIO::Storage::DBI) that
# carries the on_connect config and a custom connect_call_* method. No real DB,
# no event loop.

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::SQLMaker;

# --- A recording pool connection --------------------------------------------
# The future_io connection shape is a { dbh => $dbh } wrapper; mirror it so the
# DEFAULT runner (DBIO::Storage::Async::_run_pool_connect_statement -> $conn->{dbh}->do)
# is what gets exercised. Every do() lands in the connection's own log, so we can
# assert PER pool connection.
{
  package RecHandle;
  sub new { bless { log => $_[1] }, $_[0] }
  sub do  { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
}

{
  package RecPool;
  use base 'DBIO::Storage::PoolBase';

  my $NEXT = 0;

  sub _create_connection {
    my ($self, $conninfo) = @_;
    my @log;
    return { id => ++$NEXT, log => \@log, dbh => RecHandle->new(\@log) };
  }

  # Keep the connection (and its log) intact through shutdown so the test can
  # assert on the disconnect actions that ran against it.
  sub _shutdown_connection { }
}

# --- The fake async backend -------------------------------------------------
# Concrete DBIO::Storage::Async that overrides only the seams it needs, wiring
# itself as the RecPool's owner so the central pool-spawn hook can reach it. It
# inherits _setup_pool_connection / _teardown_pool_connection / the default
# _run_pool_connect_statement unchanged.
{
  package RecBackend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my $self = shift;
    $self->{pool} ||= RecPool->new(
      storage  => $self,
      conninfo => $self->{_conninfo} || 'fake',
      size     => $self->{_pool_size} || 5,
    );
  }
}

# --- The owning sync storage ------------------------------------------------
# isa DBIO::Storage::DBI, so it carries the on_connect_* accessors and the sync
# _do_connection_actions dispatch. Defines a connect_call_* / disconnect_call_*
# method that emits a known SQL via _do_query -- the exact convention real
# drivers use (connect_call_load_age, connect_call_use_foreign_keys, ...).
{
  package RecOwner;
  use base 'DBIO::Storage::DBI';

  sub connect_call_test_setup       { $_[0]->_do_query('SETUP CALL') }
  sub disconnect_call_test_teardown { $_[0]->_do_query('TEARDOWN CALL') }
}

my $schema = DBIO::Test->init_schema;   # kept alive: storages weaken their ref

sub wired_backend {
  my %config = @_;
  my $backend = RecBackend->new($schema);
  my $owner   = RecOwner->new($schema);

  $owner->on_connect_do($config{on_connect_do})           if exists $config{on_connect_do};
  $owner->on_connect_call($config{on_connect_call})       if exists $config{on_connect_call};
  $owner->on_disconnect_do($config{on_disconnect_do})     if exists $config{on_disconnect_do};
  $owner->on_disconnect_call($config{on_disconnect_call}) if exists $config{on_disconnect_call};

  $backend->_owner_storage($owner);
  $backend->connect_info([ { host => 'h', pool_size => $config{size} || 5 } ]);

  # return the owner too so its weak back-ref stays alive for the caller
  return ($backend, $owner);
}

# ---------------------------------------------------------------------------
# on_connect_do + on_connect_call replay on every freshly spawned connection,
# in the sync dispatch order (call before do), BEFORE the connection serves any
# query.
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(
    on_connect_call => 'test_setup',
    on_connect_do   => [ 'PRAGMA one', 'PRAGMA two' ],
    size            => 2,
  );

  my @expected = ( 'SETUP CALL', 'PRAGMA one', 'PRAGMA two' );

  my $c1 = $backend->pool->acquire->get;
  is_deeply $c1->{log}, \@expected,
    'first pool connection replayed on_connect_call then on_connect_do at spawn';

  # The replay happened at spawn, i.e. before acquire even resolved -- so it is
  # in place before the first query is ever served on this connection.
  ok scalar(@{ $c1->{log} }), 'connect actions present the moment the connection is handed out';

  # A second physical connection gets its OWN independent replay.
  my $c2 = $backend->pool->acquire->get;
  isnt $c1->{id}, $c2->{id}, 'two distinct physical connections spawned (pool size 2)';
  is_deeply $c2->{log}, \@expected,
    'second pool connection got its own full on_connect replay';

  # Idle reuse must NOT re-run the actions (spawn-only, once per physical conn).
  $backend->pool->release($c1);
  my $reused = $backend->pool->acquire->get;
  is $reused->{id}, $c1->{id}, 'released connection is reused, not re-spawned';
  is_deeply $reused->{log}, \@expected,
    'reused idle connection did not replay the on_connect actions again';
}

# ---------------------------------------------------------------------------
# connect_call dispatch: coderef form and nested-arrayref do_sql form both route
# through _do_query onto the pool connection (mirrors sync resolution order).
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(
    on_connect_call => sub { my $s = shift; $s->_do_query('CODEREF SQL') },
    on_connect_do   => 'PLAIN SQL',
    size            => 1,
  );

  my $c = $backend->pool->acquire->get;
  is_deeply $c->{log}, [ 'CODEREF SQL', 'PLAIN SQL' ],
    'coderef on_connect_call and scalar on_connect_do both ran on the pool connection';
}

{
  my ($backend, $owner) = wired_backend(
    on_connect_call => [ [ do_sql => 'NESTED DO SQL' ] ],
    size            => 1,
  );

  my $c = $backend->pool->acquire->get;
  is_deeply $c->{log}, [ 'NESTED DO SQL' ],
    'nested [[ do_sql => ... ]] on_connect_call dispatched connect_call_do_sql to the pool connection';
}

# ---------------------------------------------------------------------------
# Symmetry: on_disconnect_do / on_disconnect_call run at pool shutdown, against
# the still-live connection, with the same dispatch machinery.
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(
    on_connect_do      => 'CONNECT SQL',
    on_disconnect_call => 'test_teardown',
    on_disconnect_do   => 'DISCONNECT SQL',
    size               => 1,
  );

  my $c = $backend->pool->acquire->get;
  is_deeply $c->{log}, [ 'CONNECT SQL' ], 'connect action ran at spawn';

  $backend->pool->shutdown;
  is_deeply $c->{log},
    [ 'CONNECT SQL', 'TEARDOWN CALL', 'DISCONNECT SQL' ],
    'shutdown replayed on_disconnect_call then on_disconnect_do on the live connection';
}

# ---------------------------------------------------------------------------
# No configuration + no owner: the seam is a clean no-op (never breaks a plain
# pool spawn).
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(size => 1);   # owner wired, but no actions
  my $c = $backend->pool->acquire->get;
  is_deeply $c->{log}, [], 'no on_connect config -> nothing replayed';

  # A backend with NO owner wired at all: spawn must not blow up.
  my $bare = RecBackend->new($schema);
  $bare->connect_info([ { host => 'h', pool_size => 1 } ]);
  my $bc;
  lives_ok { $bc = $bare->pool->acquire->get } 'spawn with no owner wired is a no-op, not a crash';
  is_deeply $bc->{log}, [], 'no owner -> no connect actions';
}

# ---------------------------------------------------------------------------
# Runner seam: the default _run_pool_connect_statement handles both the
# { dbh => $dbh } wrapper and a bare do-capable handle, and croaks on anything
# else (so a native backend knows to override it).
# ---------------------------------------------------------------------------
{
  my $backend = RecBackend->new($schema);

  my @log;
  my $wrapped = { dbh => RecHandle->new(\@log) };
  $backend->_run_pool_connect_statement($wrapped, 'WRAP SQL');
  is_deeply \@log, [ 'WRAP SQL' ], 'default runner drives { dbh => $dbh } wrapper handles';

  my @bare_log;
  my $bare_handle = RecHandle->new(\@bare_log);   # blessed, ->can("do")
  $backend->_run_pool_connect_statement($bare_handle, 'BARE SQL');
  is_deeply \@bare_log, [ 'BARE SQL' ], 'default runner drives a bare do-capable handle';

  throws_ok { $backend->_run_pool_connect_statement('not-a-handle', 'X') }
    qr/override _run_pool_connect_statement/,
    'default runner croaks on an unrecognised connection shape, naming the override';
}

# ---------------------------------------------------------------------------
# _owner_storage back-reference is weak (no cycle: sync storage owns the async
# backend, not the reverse).
# ---------------------------------------------------------------------------
{
  my $backend = RecBackend->new($schema);
  {
    my $owner = RecOwner->new($schema);
    $backend->_owner_storage($owner);
    is $backend->_owner_storage, $owner, '_owner_storage getter returns the wired owner';
  }
  # $owner has gone out of scope; the weak ref must not keep it alive.
  is $backend->_owner_storage, undef, '_owner_storage is a weak reference';
}

done_testing;

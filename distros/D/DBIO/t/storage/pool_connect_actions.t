use strict;
use warnings;
use Test::More;
use Test::Exception;

# A freshly-spawned async pool connection must replay the SAME
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

use DBIO::Test;
use DBIO::Test::Future ();
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

  # A statement whose text starts with REFUSE is rejected, standing
  # in for a server that refuses an on_connect_do (an unknown search_path, a
  # missing extension, a SET the account may not issue).
  sub do  {
    my ($self, $sql) = @_;
    die "connect action refused: $sql\n" if $sql =~ /^REFUSE\b/;
    push @{ $self->{log} }, $sql;
    1;
  }

  # What a connect_call_* reads: the statement is logged, the rows come back.
  sub selectall_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @{ $self->{log} }, "SELECT-ROWS $sql";
    push @{ $self->{binds} }, [ @bind ];
    return [ [ 'row', $sql ] ];
  }
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

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my $self = shift;
    $self->{pool} ||= RecPool->new(
      storage      => $self,
      conninfo     => $self->{_conninfo} || 'fake',
      size         => $self->{_pool_size} || 5,
      future_class => $self->future_class,
    );
  }

  # A transport with a session reset (karr core k398): the connection is as
  # spawned afterwards and keeps its log, which is what these tests read.
  sub _reset_pool_connection { $_[0]->future_class->done }

  # Transport seam in the shape every real Model-B backend uses (see
  # DBIO::Async::Storage::_query_async): acquire a pooled connection, run the
  # statement on it, release it. Nothing here is synchronous outside the pool,
  # so a connect action refused at spawn can only reach the caller through the
  # Future acquire() hands back.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      push @{ $conn->{log} }, $sql;
      $self->pool->release($conn);
      return $self->future_class->done;
    });
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
  sub connect_call_test_read        {
    my $self = shift;
    $self->{read_rows} = $self->_pool_connect_rows('SELECT probe', 7);
    $self->_do_query('READ ' . scalar @{ $self->{read_rows} });
  }
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
# dbio_rows: the default runner hands back the rows, only on request.
# ---------------------------------------------------------------------------
{
  my $backend = RecBackend->new($schema);

  my @log;
  my $wrapped = { dbh => RecHandle->new(\@log) };
  is_deeply $backend->_run_pool_connect_statement($wrapped, 'Q1', { dbio_rows => 1 }, 'b'),
    [ [ 'row', 'Q1' ] ], 'dbio_rows returns the rows of a wrapper handle';
  is_deeply \@log, [ 'SELECT-ROWS Q1' ], '... read with selectall_arrayref, not do';

  my @bare_log;
  my $bare_handle = RecHandle->new(\@bare_log);
  is_deeply $backend->_run_pool_connect_statement($bare_handle, 'Q2', { dbio_rows => 1 }),
    [ [ 'row', 'Q2' ] ], 'dbio_rows returns the rows of a bare handle';
  is_deeply $bare_handle->{binds}, [ [] ], '... without binds when none are given';

  my @plain;
  my $h = RecHandle->new(\@plain);
  my @ret = $backend->_run_pool_connect_statement($h, 'EXEC', {});
  is_deeply \@ret, [], 'without the key the runner returns nothing';
  is_deeply \@plain, [ 'EXEC' ], '... and executes with do';
}

# _pool_connect_rows: the runner inside the pool replay, the own handle outside.
{
  my ($backend, $owner) = wired_backend(on_connect_call => 'test_read', size => 1);
  my $c = $backend->pool->acquire->get;
  is_deeply $c->{log}, [ 'SELECT-ROWS SELECT probe', 'READ 1' ],
    'connect_call reading rows runs on the pool connection through the runner';
  is_deeply $c->{dbh}{binds}, [ [ 7 ] ], '... with its bind values';
  is_deeply $owner->{read_rows}, [ [ 'row', 'SELECT probe' ] ], '... and got the rows back';
}
{
  package SyncOwner;
  our @ISA = ('RecOwner');
  sub dbh_do {
    my ($self, $code, @args) = @_;
    $code->($self, $self->{own_dbh}, @args);
  }
}
{
  my @own;
  my $owner = SyncOwner->new($schema);
  $owner->{own_dbh} = RecHandle->new(\@own);
  my $rows = $owner->_pool_connect_rows('SELECT sync', 1, 2);
  is_deeply $rows, [ [ 'row', 'SELECT sync' ] ], 'sync path reads the rows on the own handle';
  is_deeply $owner->{own_dbh}{binds}, [ [ 1, 2 ] ], '... with its binds';

  {
    no warnings 'redefine';
    local *RecHandle::selectall_arrayref = sub { die "boom SELECT secret\n" };
    throws_ok { $owner->_pool_connect_rows('SELECT secret') } qr/boom/,
      'a failing read throws';
  }
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

# ---------------------------------------------------------------------------
# A refused connect action is an OPERATIONAL failure and must reach
# the caller the way every other operational failure on the async path does --
# as a failed Future. The pool spawns synchronously inside _acquire_slot, so
# before the fix the exception escaped acquire() (and with it select_async)
# before any Future existed: the ->catch the Future contract teaches callers
# to write was the one place the error could never arrive.
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(
    on_connect_do => 'REFUSE SET search_path = nope',
    size          => 2,
  );

  my $f;
  lives_ok { $f = $backend->select_async('artist', [ 'artistid' ], {}) }
    'a refused connect action does not escape select_async as an exception';

  isa_ok $f, 'DBIO::Test::Future',
    'select_async still handed back a Future';
  ok $f->is_ready,  'the returned Future is already resolved';
  ok $f->is_failed, 'and it is failed, not done';
  my $caught;
  $f->catch(sub { $caught = $_[0]; return $_[0] });
  like $caught, qr/connect action refused: REFUSE SET search_path/,
    'catch receives the connect-action error the server raised';

  # acquire() itself, the other entry point named in the ticket.
  my $af;
  lives_ok { $af = $backend->pool->acquire }
    'pool->acquire does not throw either';
  ok $af->is_failed, 'pool->acquire hands back a failed Future';
}

# ---------------------------------------------------------------------------
# Second half: the failed connection is pushed onto the pool's
# _connections before the connect actions run, so a spawn that dies used to
# leave it counted against max_size for good -- never handed out, never
# released, never reused. A pool whose connect actions keep being refused
# leaked one slot per attempt until it could only return pending waiters.
# ---------------------------------------------------------------------------
{
  my ($backend, $owner) = wired_backend(
    on_connect_do => 'REFUSE SET search_path = nope',
    size          => 2,
  );
  my $pool = $backend->pool;

  is $pool->size, 0, 'pool starts with no connections';

  # More failed acquires than the pool is allowed to hold.
  for my $attempt (1 .. 3) {
    my $af = $pool->acquire;
    ok $af->is_failed, "failed acquire $attempt reports failure";
    is $pool->size, 0,
      "attempt $attempt did not leave a connection counted against max_size";
  }

  is $pool->available, 0, 'and nothing half-configured reached the idle pool';

  # Capacity is genuinely intact: once the server stops refusing, the very next
  # acquire spawns and resolves instead of queueing behind two dead slots.
  $owner->on_connect_do('SET search_path = fine');
  my $good = $pool->acquire;
  ok $good->is_ready && !$good->is_failed,
    'the next acquire after a fixed connect action resolves';
  my $conn = $good->get;
  is_deeply $conn->{log}, [ 'SET search_path = fine' ],
    'the connection that finally succeeded carries its replay';
  is $pool->size, 1, 'exactly one live connection is counted';
}

# ---------------------------------------------------------------------------
# A refused replay is the failure of the POOL connection it ran on. The owning
# sync storage's own handle is another connection, which the refusal never
# touched: dropping it throws away a live session, and with it a transaction
# the owner holds open on it (karr k251). Only a connect action failing on the
# owner's OWN connection -- which that failure left half-configured -- drops
# the owner's handle.
# ---------------------------------------------------------------------------
{
  package HandleOwner;
  use base 'DBIO::Test::Storage';

  # DBIO::Test::Storage's _dbh ignores writes, so it cannot show that anything
  # dropped the owner's handle. This owner keeps them, as the plain accessor on
  # DBIO::Storage::DBI does, and derives "connected" from the handle the way
  # DBIO::Storage::DBI does -- an owner whose handle was dropped can no longer
  # commit.
  sub _dbh {
    my $self = shift;
    $self->{_fake_dbh} = shift if @_;
    $self->{_fake_dbh};
  }
  sub _seems_connected { ($_[0]->_dbh || return 0)->FETCH('Active') }
}

{
  my $owner   = HandleOwner->new($schema);
  my $backend = RecBackend->new($schema);
  $owner->on_connect_do('REFUSE SET search_path = nope');
  $backend->_owner_storage($owner);
  $backend->connect_info([ { host => 'h', pool_size => 2 } ]);

  $owner->txn_begin;
  my $handle = $owner->_dbh;
  ok $handle, 'the owner holds its own handle';
  is $owner->transaction_depth, 1, 'and has a transaction open on it';

  my $f = $backend->pool->acquire;
  ok $f->is_failed, 'a connect action refused on a new pool connection fails the acquire';
  my $caught;
  $f->catch(sub { $caught = $_[0]; return $_[0] });
  like $caught, qr/connect action refused: REFUSE SET search_path/,
    '... with the refusal';
  is $backend->pool->size, 0, '... and the pool connection is retired';

  is $owner->_dbh, $handle, "the owner's own handle is still the one it held";
  is $owner->transaction_depth, 1, 'its transaction is still open';

  $owner->reset_captured;
  lives_ok { $owner->txn_commit } 'and it commits';
  is_deeply [ map { $_->{sql} } $owner->captured_queries ], [ 'COMMIT' ],
    '... on its own connection';
}

{
  my $owner = HandleOwner->new($schema);
  $owner->on_connect_call(sub { die "owner session setup refused\n" });
  ok $owner->_dbh, 'an owner with a handle';

  throws_ok { $owner->_run_connection_actions }
    qr/owner session setup refused/,
    "a connect action failing on the owner's own connection throws";
  is $owner->_dbh, undef, "... and drops the owner's half-configured handle";
}

done_testing;

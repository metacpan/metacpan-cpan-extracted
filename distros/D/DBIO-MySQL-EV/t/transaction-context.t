use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::EV::TransactionContext;
use DBIO::MySQL::EV::Storage;

# Minimal mock storage and connection. Each CRUD method records the
# operation AND the connection it was handed, so we can assert that the
# context pins every CRUD op to the txn connection (txn_conn, alias
# txn_mdb) rather than acquiring a fresh pooled one.
#
# Since karr k31 the context is a THIN SUBCLASS of core's generic
# DBIO::Storage::Async::TransactionContext: it inherits the whole surface
# exercised below and contributes only the txn_mdb alias. The constructor
# key is therefore core's txn_conn, matching
# DBIO::MySQL::EV::Storage::_txn_conn_accessor.
{
  package MockStorageMySQL;
  sub new { bless { pool => MockPoolMySQL->new }, $_[0] }
  sub pool        { $_[0]->{pool} }
  sub in_txn      { 0 }
  # core karr k196 / ADR 0045 section 4: the context snapshots the backend's
  # opaque generation token at construction, and every CRUD op asks the OWNING
  # sync storage to prove ownership via _assert_context_active. This mock is not
  # a real DBIO::Storage::Async, so it supplies the two seams the context now
  # needs: a stable per-instance generation token, and an owner that accepts it.
  # Ownership ACCEPT/REFUSE itself is exercised end-to-end (real backends, real
  # tokens) in t/with-context-ownership-mock.t; here it must simply pass so the
  # PINNING claims below (every CRUD op runs on txn_conn) can run at all.
  sub _context_owner_token { $_[0]->{_owner_token} ||= \(my $opaque) }
  sub _owner_storage       { $_[0]->{_owner} ||= MockOwnerMySQL->new }
  sub sql_maker   { $_[0]->{sql_maker} // 'MockSQLMaker' }
  sub debug       { $_[0]->{debug}     // 'DEBUG' }
  sub _query_async_pinned {
    my ($self, $mdb, $sql, $bind) = @_;
    push @{ $self->{_queries} //= [] }, [pinned => $sql];
    return Future->done([]);
  }
  # The real entry point the TransactionContext now uses for ALL CRUD.
  # Records the op and the connection it was pinned to.
  sub _run_crud_pinned {
    my ($self, $op, $mdb, @args) = @_;
    push @{ $self->{_crud} //= [] }, { op => $op, mdb => $mdb };
    return Future->done([]);
  }
  # These should NOT be reached by the context anymore — if they are, the
  # query is escaping the transaction onto a fresh pool connection.
  sub select_async        { die 'select_async on storage MUST NOT be called from txn context' }
  sub select_single_async { die 'select_single_async on storage MUST NOT be called from txn context' }
  sub update_async        { die 'update_async on storage MUST NOT be called from txn context' }
  sub delete_async        { die 'delete_async on storage MUST NOT be called from txn context' }
  sub insert_async        { die 'insert_async on storage MUST NOT be called from txn context' }
  # core karr k213: the context's pipeline runs the scaffold on the PINNED txn
  # connection via _pipeline_on_conn, with NO release coderef (the connection
  # belongs to the transaction boundary). Record exactly what it is handed:
  # every argument after the coderef, the first of which is the release slot.
  # Since core karr k232 the context fills that slot with an explicit undef and
  # passes a $retire coderef after it; before k232 it passed nothing there.
  # core karr k218: the context asks _pipeline_refusal BEFORE touching the txn
  # connection. This mock plays a transport that CAN pipeline (undef = no
  # refusal), because what this file pins is the context's routing onto
  # _pipeline_on_conn. The refusal path of the real EV transport (which cannot
  # pipeline, ADR 0009) is pinned in t/txn-context-pipeline-mock.t.
  sub _pipeline_refusal { undef }
  sub _pipeline_on_conn {
    my ($self, $conn, $code, @release) = @_;
    push @{ $self->{_pipeline_on_conn} //= [] },
      { conn => $conn, code => $code, release => [@release] };
    return Future->done('PIPELINE_RESULT');
  }
  # Neither may be reached from the context any more (core karr k213): the
  # storage's pipeline acquires a SECOND pool connection (batch outside the
  # txn), and the storage's txn_do_async opens an INDEPENDENT transaction.
  sub pipeline     { push @{$_[0]->{_queries} //= []}, 'pipeline';     Future->done([]) }
  sub txn_do_async { push @{$_[0]->{_queries} //= []}, 'txn_do_async'; Future->done([]) }
  sub select          { push @{$_[0]->{_queries} //= []}, 'select'; 'SELECT_RESULT' }
  sub select_single   { push @{$_[0]->{_queries} //= []}, 'select_single'; 'SELECT_SINGLE_RESULT' }
  sub insert          { push @{$_[0]->{_queries} //= []}, 'insert'; 'INSERT_RESULT' }
  sub update          { push @{$_[0]->{_queries} //= []}, 'update'; 'UPDATE_RESULT' }
  sub delete          { push @{$_[0]->{_queries} //= []}, 'delete'; 'DELETE_RESULT' }
}
{
  package MockPoolMySQL;
  sub new { bless {}, $_[0] }
  sub acquire { push @{ $_[0]->{_calls} //= [] }, 'acquire'; Future->done(MockConnMySQL->new) }
  sub release { push @{ $_[0]->{_calls} //= [] }, 'release'; }
}
{
  # The owning sync storage core's _assert_context_active consults. Ownership
  # comparison is tested for real elsewhere (t/with-context-ownership-mock.t);
  # this stub accepts unconditionally so it does not shadow the pinning claims.
  package MockOwnerMySQL;
  sub new { bless {}, $_[0] }
  sub _assert_async_context_owner { $_[1] }
}
{
  package MockConnMySQL;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorageMySQL->new;
my $mdb     = MockConnMySQL->new;
my $ctx     = DBIO::MySQL::EV::TransactionContext->new(
  storage  => $storage,
  txn_conn => $mdb,
);

isa_ok $ctx, 'DBIO::MySQL::EV::TransactionContext';
isa_ok $ctx, 'DBIO::Storage::Async::TransactionContext',
  'the EV txn context (karr k31: a thin subclass of the core generic one)';

# The constructor key is core's txn_conn, NOT the pre-k31 private 'mdb'.
# Core's txn_do_async builds the context with the key _txn_conn_accessor
# names, so a context that still demanded 'mdb' would be built without a
# connection -- this pins that the two agree.
throws_ok {
  DBIO::MySQL::EV::TransactionContext->new(storage => $storage, mdb => $mdb)
} qr/txn_conn required/,
  "constructor demands the core 'txn_conn' key (the old 'mdb' key is gone)";
is(DBIO::MySQL::EV::Storage->_txn_conn_accessor, 'txn_conn',
  'the storage seam passes the connection under exactly that key');

# in_txn: context reports 1, storage reports 0
ok  $ctx->in_txn,     'in_txn returns true on context';
is  $ctx->in_txn, 1,  'in_txn is exactly 1 on context';
is  $storage->in_txn, 0, 'storage in_txn is 0';

# txn_conn (core) returns the pinned connection, and txn_mdb is its alias.
# txn_conn is what core's own callers reach for -- deploy_async's
# transactional branch among them -- while txn_mdb is the name this driver
# has always exposed (t/13-async-e2e.t asserts connection affinity through
# it), so both must answer the same handle.
is $ctx->txn_conn, $mdb, 'txn_conn returns the connection';
is $ctx->txn_mdb, $mdb, 'txn_mdb returns the connection';
is $ctx->txn_mdb, $ctx->txn_conn, 'txn_mdb is an alias for txn_conn';

# pool delegates to storage
is $ctx->pool, $storage->pool, 'pool delegates to underlying storage';

# _query_async routes to the pinned path (no acquire-from-pool)
$storage->{_queries} = [];
my $f = $ctx->_query_async('SELECT 1', []);
isa_ok $f, 'Future', '_query_async returns a Future';
is_deeply $storage->{_queries}, [[pinned => 'SELECT 1']],
  '_query_async routes through _query_async_pinned (pinned connection)';

# BUG 2 regression: ALL CRUD async methods must run pinned on the txn
# connection via _run_crud_pinned, NOT acquire a fresh pooled connection.
# Before the fix, select/update/delete/select_single forwarded to
# $storage->*_async (a fresh pool->acquire) and ran OUTSIDE the txn — the
# storage mocks above die loudly if that regression returns.
for my $op (qw(select select_single insert update delete)) {
  my $method = "${op}_async";
  $storage->{_crud} = [];
  my $cf = $ctx->$method('artist', '*', { id => 1 });
  isa_ok $cf, 'Future', "$method returns a Future";
  is scalar @{ $storage->{_crud} }, 1, "$method issues exactly one CRUD op";
  is $storage->{_crud}[0]{op}, $op, "$method routes op '$op' through _run_crud_pinned";
  is $storage->{_crud}[0]{mdb}, $mdb,
    "$method pins op '$op' to the txn connection (same mdb, not a fresh pool conn)";
}

# pipeline / txn_do_async (core karr k213, replaces the pre-k213 claim).
# The OLD claim here was "pipeline and txn_do_async forward to the storage's
# methods of the same name". That forwarding is exactly what k213 removed:
# storage->pipeline acquired a SECOND pool connection, so the batch ran outside
# the transaction; storage->txn_do_async opened an INDEPENDENT transaction on
# yet another connection. The NEW claims:
#   pipeline     -- runs the scaffold on THIS txn's pinned connection through
#                   _pipeline_on_conn, passes NO release coderef (only the txn
#                   boundary may release it), touches neither the pool nor
#                   storage->pipeline.
#   txn_do_async -- refuses loudly with a DBIO::Exception and never reaches
#                   storage->txn_do_async.
# The release claim is about the release SLOT, the argument after the coderef:
# it must be undef. Core karr k232 passes (undef, $retire) there -- the retire
# coderef marks the context for the boundary instead of releasing, and is
# core's to test (t/test/41_async_txn_pipeline_retire.t); a core before k232
# passes nothing, which leaves the slot undef too.
{
  $storage->{_queries}           = [];
  $storage->{_pipeline_on_conn}  = [];
  $storage->pool->{_calls}       = [];
  my $code = sub { };
  my $pf = $ctx->pipeline($code);
  isa_ok $pf, 'Future', 'pipeline returns a Future';
  is $pf->get, 'PIPELINE_RESULT', 'pipeline hands back the scaffold Future';
  is scalar @{ $storage->{_pipeline_on_conn} }, 1,
    'pipeline runs the scaffold exactly once via _pipeline_on_conn';
  my $call = $storage->{_pipeline_on_conn}[0];
  is $call->{conn}, $mdb, 'pipeline runs on the pinned txn connection';
  is $call->{code}, $code, 'pipeline passes the caller coderef through';
  ok !defined $call->{release}[0],
    'pipeline passes NO release coderef: the release slot after the coderef is undef (txn connection stays pinned)';
  is_deeply $storage->pool->{_calls}, [],
    'pipeline neither acquires nor releases a pool connection';
  is_deeply $storage->{_queries}, [],
    'pipeline does NOT forward to storage->pipeline';
}
{
  $storage->{_queries}   = [];
  $storage->pool->{_calls} = [];
  my $ran = 0;
  throws_ok { $ctx->txn_do_async(sub { $ran++; Future->done }) }
    'DBIO::Exception', 'nested txn_do_async throws a DBIO::Exception';
  like "$@", qr/nested txn_do_async/, '... naming the nested txn_do_async';
  ok !$ran, '... without running the coderef';
  is_deeply $storage->{_queries}, [],
    'nested txn_do_async does NOT reach storage->txn_do_async';
  is_deeply $storage->pool->{_calls}, [],
    'nested txn_do_async touches no pool connection';
}

# Sync CRUD methods: run the *_async path (pinned) and ->get the result.
# We assert they too go through _run_crud_pinned with the txn connection.
for my $op (qw(select select_single insert update delete)) {
  $storage->{_crud} = [];
  my $r = $ctx->$op('artist', '*', { id => 1 });
  is scalar @{ $storage->{_crud} }, 1, "sync $op issues exactly one CRUD op";
  is $storage->{_crud}[0]{op}, $op, "sync $op routes op '$op' through _run_crud_pinned";
  is $storage->{_crud}[0]{mdb}, $mdb, "sync $op pins op '$op' to the txn connection";
}

# Accessors: return the storage's value
is $ctx->sql_maker, 'MockSQLMaker', 'sql_maker delegates to storage';
is $ctx->debug,     'DEBUG',        'debug delegates to storage';

# Unknown method does NOT silently forward (AUTOLOAD was removed)
{
  my $died = !eval { $ctx->this_method_does_not_exist(); 1 };
  ok $died, 'unknown method does NOT silently forward (dies)';
  like $@, qr/this_method_does_not_exist|locate.*method|Can.t locate/i,
    'error is the standard "method not found" message, not a silent forward';
}

# ADR 0045: a context-bound ResultSet/Row/ResultSetColumn asks the context
# whether it may still route an *_async op onto it. Unlike a pipeline
# context, a transaction context stays active for the whole transaction --
# its connection is pinned from BEGIN to COMMIT -- so _context_active is
# true for a live context. Inherited since karr k31; before that the class
# had no _context_active at all and core's can()-probe silently treated it
# as always-active, which is exactly the drift this pins.
ok $ctx->_context_active, '_context_active is true on a live txn context';

# _invalidate exists for a transport that wants to enforce the boundary
# itself; the scaffold does not call it mid-transaction. Asserted last --
# it makes the context refuse further work by contract.
$ctx->_invalidate;
ok !$ctx->_context_active, '_context_active goes false after _invalidate';

done_testing;

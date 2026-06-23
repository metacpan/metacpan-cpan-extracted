use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::Async::TransactionContext;

# Minimal mock storage and connection. Each CRUD method records the
# operation AND the connection it was handed, so we can assert that the
# context pins every CRUD op to the txn connection (txn_mdb) rather than
# acquiring a fresh pooled one.
{
  package MockStorageMySQL;
  sub new { bless { pool => MockPoolMySQL->new }, $_[0] }
  sub pool        { $_[0]->{pool} }
  sub in_txn      { 0 }
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
  sub pipeline        { push @{$_[0]->{_queries} //= []}, 'pipeline'; Future->done([]) }
  sub txn_do_async    { push @{$_[0]->{_queries} //= []}, 'txn_do_async'; Future->done([]) }
  sub select          { push @{$_[0]->{_queries} //= []}, 'select'; 'SELECT_RESULT' }
  sub select_single   { push @{$_[0]->{_queries} //= []}, 'select_single'; 'SELECT_SINGLE_RESULT' }
  sub insert          { push @{$_[0]->{_queries} //= []}, 'insert'; 'INSERT_RESULT' }
  sub update          { push @{$_[0]->{_queries} //= []}, 'update'; 'UPDATE_RESULT' }
  sub delete          { push @{$_[0]->{_queries} //= []}, 'delete'; 'DELETE_RESULT' }
}
{
  package MockPoolMySQL;
  sub new { bless {}, $_[0] }
  sub release { }
}
{
  package MockConnMySQL;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorageMySQL->new;
my $mdb     = MockConnMySQL->new;
my $ctx     = DBIO::MySQL::Async::TransactionContext->new(
  storage => $storage,
  mdb     => $mdb,
);

isa_ok $ctx, 'DBIO::MySQL::Async::TransactionContext';

# in_txn: context reports 1, storage reports 0
ok  $ctx->in_txn,     'in_txn returns true on context';
is  $ctx->in_txn, 1,  'in_txn is exactly 1 on context';
is  $storage->in_txn, 0, 'storage in_txn is 0';

# txn_mdb returns the pinned connection
is $ctx->txn_mdb, $mdb, 'txn_mdb returns the connection';

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

# pipeline and txn_do_async: same Future-returning delegation contract
for my $method (qw(pipeline txn_do_async)) {
  $storage->{_queries} = [];
  my $pf = $ctx->$method(sub { });
  isa_ok $pf, 'Future', "$method returns a Future from storage";
  is_deeply $storage->{_queries}, [$method],
    "$method forwards to storage (recorded once)";
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

done_testing;

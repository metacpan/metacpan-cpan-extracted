use strict;
use warnings;
use Test::More;
use Scalar::Util ();

use Future;

use DBIO::Async::TransactionContext;

# Minimal mock storage and connection.
#
# The mock records, per executed query, WHICH execution seam it went
# through and WHICH connection it ran on. This is what lets the tests
# below catch the pinning bug: if a context CRUD call ever forwarded to
# the non-pinned _query_async (a fresh pool connection) instead of the
# pinned path, the recorded seam/conn would be wrong and the assertions
# would fail.
{
  package MockStorage5;
  sub new { bless { pool => MockPool5->new, _log => [], _owner_token => \(my $t) }, $_[0] }
  sub pool { $_[0]->{pool} }
  sub sql_maker { 'MockSQLMaker5' }
  sub _txn_conn_accessor { 'txn_conn' }

  # k196 / ADR 0045 §4 ownership contract (adopted from core 0.900004): core's
  # generic TransactionContext snapshots the backend's owner token at
  # construction and, on every pinned op, resolves the backend's owner and has
  # THAT owner prove ownership of the context (_assert_context_active ->
  # _owner_storage -> _assert_async_context_owner). This mock is a SINGLE
  # ownership domain: it is its own owner, with a stable per-object token. The
  # ownership check is the FAITHFUL token comparison core's DBIO::Storage::DBI
  # runs -- same generation accepted, a context from a different backend
  # refused -- not an unconditional accept, so the pinning assertions below
  # genuinely depend on the ownership machinery and the refusal is provable
  # (see the "foreign context" block at the end of this file).
  sub _context_owner_token { $_[0]->{_owner_token} }
  sub _owner_storage       { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context ownership cannot be proven\n"
      unless Scalar::Util::blessed($ctx) && $ctx->can('_context_owner_token');
    my $ours   = $self->_context_owner_token;
    my $theirs = $ctx->_context_owner_token;
    die "async context does not belong to this storage generation\n"
      unless $ours && $theirs
          && Scalar::Util::refaddr($ours) == Scalar::Util::refaddr($theirs);
    return $ctx;
  }

  # Non-pinned path: must NOT be reached by a TransactionContext.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pooled', conn => undef, sql => $sql };
    return Future->done([]);
  }
  # Pinned path: the only correct seam for in-txn CRUD. Returns the
  # result as a flat list of rows, matching the real _query_async_pinned
  # which does $f->done(@$rows).
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pinned', conn => $conn, sql => $sql };
    return Future->done(['row']);
  }

  # Shared CRUD builder seam, mirroring the real storage: builds a label
  # for the op and runs it on the pinned connection. The select_single
  # first-row post-processing is exercised here so the context's reliance
  # on it is covered.
  sub _run_crud_pinned {
    my ($self, $op, $conn, @args) = @_;
    my $sql = "MOCK $op";
    my $f = $self->_query_async_pinned($conn, $sql, []);
    return $f unless $op eq 'select_single';
    return $f->then(sub { my @rows = @_; return @rows ? $rows[0] : undef });
  }
}
{
  package MockPool5;
  sub new { bless {}, $_[0] }
  sub release { }
}
{
  package MockConn5;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorage5->new;
my $conn    = MockConn5->new;
my $ctx     = DBIO::Async::TransactionContext->new(
  storage  => $storage,
  txn_conn => $conn,
);

isa_ok $ctx, 'DBIO::Async::TransactionContext';

# in_txn is always true
ok $ctx->in_txn, 'in_txn returns true';

# txn_conn returns the pinned connection
is $ctx->txn_conn, $conn, 'txn_conn returns the connection';

# pool delegates to storage
is $ctx->pool, $storage->pool, 'pool delegates to underlying storage';

# _query_async forwards to the pinned execution path
my $f = $ctx->_query_async('SELECT 1', []);
isa_ok $f, 'Future';
is $storage->{_log}[-1]{seam}, 'pinned', '_query_async uses the pinned seam';
is $storage->{_log}[-1]{conn}, $conn, '_query_async runs on the pinned connection';

# --- The core assertion: CRUD through the context MUST hit the
# pinned connection, never a fresh pooled one. ---

$storage->{_log} = [];

$ctx->select_async('artist', ['*'], {})->get;
$ctx->insert_async('artist', { name => 'x' })->get;
$ctx->update_async('artist', { name => 'y' }, { id => 1 })->get;
$ctx->delete_async('artist', { id => 1 })->get;
my $single = $ctx->select_single_async('artist', ['*'], { id => 1 })->get;

is scalar(@{ $storage->{_log} }), 5, 'all five CRUD calls executed';

ok( (!grep { $_->{seam} ne 'pinned' } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned seam (not the pooled _query_async)' );

ok( (!grep { !defined $_->{conn} || $_->{conn} != $conn } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned connection' );

# select_single still post-processes to the first row through the context
is_deeply $single, ['row'], 'select_single_async returns the first row';

# Sync wrappers run through the same pinned async path
$storage->{_log} = [];
$ctx->insert('artist', { name => 'sync' });
is $storage->{_log}[-1]{seam}, 'pinned', 'sync insert() also pins the connection';

# --- Ownership refusal (k196 / ADR 0045 §4). ---
#
# The accepting owner above is only half the contract: a context minted against
# ONE backend generation must be REFUSED by another. Because the mock owner runs
# core's real token comparison rather than an unconditional accept, this refusal
# is exercised through the very seam the pinning path relies on. Two distinct
# backend objects carry distinct tokens, so a context of storage B is not owned
# by storage A.
{
  my $other   = MockStorage5->new;
  my $ctx_other = DBIO::Async::TransactionContext->new(
    storage  => $other,
    txn_conn => MockConn5->new,
  );

  isnt Scalar::Util::refaddr($storage->_context_owner_token),
       Scalar::Util::refaddr($other->_context_owner_token),
    'two backend generations carry distinct ownership tokens';

  # Same-generation context is accepted (the property the pinning path uses).
  my $ok = eval { $storage->_assert_async_context_owner($ctx); 1 };
  ok $ok, 'a context of this backend generation is accepted';

  # A foreign-generation context is refused, with the generation-mismatch message.
  my $refused = eval { $storage->_assert_async_context_owner($ctx_other); 1 };
  ok !$refused, 'a foreign-generation context is refused';
  like $@, qr/does not belong to this storage generation/,
    '... with the generation-mismatch reason';

  # A context-shaped object with no ownership evidence fails closed.
  my $impostor = eval {
    $storage->_assert_async_context_owner(bless {}, 'NotAContext5'); 1
  };
  ok !$impostor, 'an object carrying no ownership token fails closed';
  like $@, qr/ownership cannot be proven/,
    '... rather than being silently accepted';
}

done_testing;

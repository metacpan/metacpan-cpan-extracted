use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::PostgreSQL::EV::TransactionContext;

# Minimal mock storage and connection.
#
# The mock records, per executed query, WHICH execution seam it went
# through and WHICH connection it ran on. This is what lets the tests
# below catch the pinning bug: if a context CRUD call ever forwarded to
# the non-pinned _query_async (a fresh pool connection) instead of the
# pinned path, the recorded seam/conn would be wrong and the assertions
# would fail.
{
  package MockStorage27;
  sub new { bless { pool => MockPool27->new, _log => [] }, $_[0] }
  sub pool { $_[0]->{pool} }
  sub sql_maker { 'MockSQLMaker27' }

  # Non-pinned path: must NOT be reached by a TransactionContext.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pooled', pg => undef, sql => $sql };
    return Future->done([]);
  }
  # Pinned path: the only correct seam for in-txn CRUD. Returns the
  # result as a flat list of rows, matching the real _query_async_pinned
  # which does $f->done(@$rows).
  sub _query_async_pinned {
    my ($self, $pg, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pinned', pg => $pg, sql => $sql };
    return Future->done(['row']);
  }

  # Shared CRUD builder seam, mirroring the real storage: builds a label
  # for the op and runs it on the pinned connection. The select_single
  # first-row post-processing is exercised here so the context's reliance
  # on it is covered.
  sub _run_crud_pinned {
    my ($self, $op, $pg, @args) = @_;
    my $sql = "MOCK $op";
    my $f = $self->_query_async_pinned($pg, $sql, []);
    return $f unless $op eq 'select_single';
    return $f->then(sub { my @rows = @_; return @rows ? $rows[0] : undef });
  }
}
{
  package MockPool27;
  sub new { bless {}, $_[0] }
  sub release { }
}
{
  package MockConn27;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorage27->new;
my $pg      = MockConn27->new;
my $ctx     = DBIO::PostgreSQL::EV::TransactionContext->new(
  storage => $storage,
  pg      => $pg,
);

isa_ok $ctx, 'DBIO::PostgreSQL::EV::TransactionContext';

# in_txn is always true
ok $ctx->in_txn, 'in_txn returns true';

# txn_pg returns the pinned connection
is $ctx->txn_pg, $pg, 'txn_pg returns the connection';

# pool delegates to storage
is $ctx->pool, $storage->pool, 'pool delegates to underlying storage';

# _query_async forwards to the pinned execution path
my $f = $ctx->_query_async('SELECT 1', []);
isa_ok $f, 'Future';
is $storage->{_log}[-1]{seam}, 'pinned', '_query_async uses the pinned seam';
is $storage->{_log}[-1]{pg}, $pg, '_query_async runs on the pinned connection';

# --- The core of the ticket: CRUD through the context MUST hit the
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

ok( (!grep { !defined $_->{pg} || $_->{pg} != $pg } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned connection' );

# select_single still post-processes to the first row through the context
is_deeply $single, ['row'], 'select_single_async returns the first row';

# Sync wrappers run through the same pinned async path
$storage->{_log} = [];
$ctx->insert('artist', { name => 'sync' });
is $storage->{_log}[-1]{seam}, 'pinned', 'sync insert() also pins the connection';

done_testing;

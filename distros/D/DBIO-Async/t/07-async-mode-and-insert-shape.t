use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use Future;
use DBIO::SQLMaker;          # the skeleton's sql_maker_class default needs it loaded
use DBIO::Storage::DBI;      # for the resolver assertion below
use DBIO::Async;             # provides the shared future_io backend base
use DBIO::Async::Storage;

# OFFLINE test for the ADR 0030/0031 contracts dbio-async must satisfy against
# the per-connection async-mode core. No real DB, no event loop -- the storage
# seam hooks are stubbed and the query path is short-circuited with a plain
# resolved Future.

# -----------------------------------------------------------------------
# 1. ADR 0030 refinement (karr #65): `use DBIO::Async` no longer globally
#    registers future_io on the core base. The mode's transport adapter is
#    resolved per driver by CONVENTION (ref($storage) . '::Async') in core, so
#    there is no generic future_io registration to find here. DBIO::Async::Storage
#    stays the abstract Future::IO base that each driver's ::Storage::Async
#    adapter subclasses.
# -----------------------------------------------------------------------

is(
  DBIO::Storage::DBI->_resolve_async_mode_class('future_io'),
  undef,
  "future_io is not globally registered -- resolved per-driver by convention",
);

# -----------------------------------------------------------------------
# Stub source + storage: bypass Future::IO entirely by overriding
# _query_async to return a plain resolved Future. _post_insert_sql appends
# RETURNING * so the insert path produces a row to fold back.
# -----------------------------------------------------------------------

{
  package SrcStub7;
  # A minimal result-source stand-in: a name (for SQLMaker) and a declared
  # column order (for RETURNING * -> hashref mapping).
  sub new     { bless {}, shift }
  sub name    { 'artist' }
  sub columns { qw(artistid name rank) }
}

{
  package TestStorage7;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { ' RETURNING *' }
  sub _normalize_conninfo       { $_[1] }
  sub _conn_ready               { 1 }
  sub _create_pool_connection   { bless {}, 'FakeConn7' }
  sub _shutdown_pool_connection { }
  sub _txn_context_class        { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor        { 'txn_conn' }
  sub _pipeline_enter           { }
  sub _pipeline_sync            { Future->done }
  sub _pipeline_exit            { }

  our $LAST_SQL;

  # Short-circuit the wire: INSERT yields a positional RETURNING * row
  # (artistid, name, rank); SELECT yields raw arrayref rows. Both pooled and
  # pinned paths funnel through here.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    $LAST_SQL = $sql;
    return Future->done([ 42, 'Miles', 13 ]) if $sql =~ /^\s*INSERT/i;
    return Future->done([ 1, 'a', 13 ], [ 2, 'b', 13 ]);
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    return $self->_query_async($sql, $bind);
  }
}

sub new_storage {
  my $s = TestStorage7->new(undef);
  $s->connect_info([{ host => 'localhost' }]);
  return $s;
}

# -----------------------------------------------------------------------
# 2. ADR 0031 §3: insert_async resolves the returned-columns HASHREF
#    (autoinc PK folded in from a positional RETURNING * row), not the raw
#    arrayref row -- exactly what create_async / Row::insert_async consume.
# -----------------------------------------------------------------------

{
  my $storage = new_storage;
  my $src     = SrcStub7->new;

  my $f = $storage->insert_async($src, { name => 'Miles' });
  isa_ok $f, 'Future', 'insert_async returns a Future';

  my $returned = $f->get;
  is ref($returned), 'HASH',
    'insert_async resolves with a returned-columns HASHREF (not a raw row)';
  is_deeply $returned,
    { artistid => 42, name => 'Miles', rank => 13 },
    'autoinc PK and RETURNING columns folded onto the insert data';

  like $TestStorage7::LAST_SQL, qr/^INSERT INTO artist .*RETURNING \*$/,
    'SQL built from the blessed source via ->name, with RETURNING * appended';
}

# -----------------------------------------------------------------------
# 3. insert_async accepts the alternate row shape too: a column=>value
#    hashref from _collect_result is merged onto the insert data.
# -----------------------------------------------------------------------

{
  package TestStorage7Hash;
  our @ISA = ('TestStorage7');
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    return Future->done({ artistid => 99, name => 'Coltrane', rank => 13 })
      if $sql =~ /^\s*INSERT/i;
    return Future->done();
  }
}
{
  my $storage = TestStorage7Hash->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);

  my $returned = $storage->insert_async('artist', { name => 'Coltrane' })->get;
  is_deeply $returned,
    { artistid => 99, name => 'Coltrane', rank => 13 },
    'hashref RETURNING row is merged into the returned-columns hashref';
}

# -----------------------------------------------------------------------
# 4. The read side is unchanged: select_async resolves a LIST of raw row
#    arrayrefs and select_single_async a single raw arrayref -- the sync
#    cursor shape the core RS layer inflates. (Guards against the insert
#    change leaking into the select path.)
# -----------------------------------------------------------------------

{
  my $storage = new_storage;

  my @rows = $storage->select_async('artist', ['*'], {})->get;
  is scalar(@rows), 2, 'select_async resolves with the full row list';
  is_deeply \@rows, [ [ 1, 'a', 13 ], [ 2, 'b', 13 ] ],
    'select_async rows stay raw arrayrefs (unchanged shape)';

  my $single = $storage->select_single_async('artist', ['*'], {})->get;
  is_deeply $single, [ 1, 'a', 13 ],
    'select_single_async resolves with a single raw arrayref';
}

# -----------------------------------------------------------------------
# 5. The transaction path shares the same builder, so in-txn insert_async
#    also resolves the returned-columns hashref (via _run_crud_pinned).
# -----------------------------------------------------------------------

{
  my $storage = new_storage;
  my $conn    = bless {}, 'FakeConn7';
  my $src     = SrcStub7->new;

  my $returned = $storage->_run_crud_pinned('insert', $conn, $src, { name => 'Miles' })->get;
  is_deeply $returned,
    { artistid => 42, name => 'Miles', rank => 13 },
    'pinned (txn) insert_async resolves the same returned-columns hashref';
}

done_testing;

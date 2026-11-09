use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::MySQL::EV::Storage;

# OFFLINE unit coverage for karr #22 (the surviving half -- the "pipeline
# behavior" half was voided by #24: this transport has no pipeline, see
# ADR 0009 and t/06-thin-transport-structure.t).
#
# Before this file, DBIO::MySQL::EV::Storage::_run_crud_pinned and
# _insert_returned_columns were exercised ONLY inside live-gated
# t/13-async-e2e.t (needs a real EV::MariaDB socket) and indirectly, at the
# happy-path only, through insert_async in t/storage-facade-mock.t (which
# mocks the CONNECTION under the real QueryExecutor). This file goes one
# layer up: it mocks the QueryExecutor itself, calls _run_crud_pinned
# directly (the entry point TransactionContext and insert_async both use),
# and drives the _auto_increment_column heuristic through
# _insert_returned_columns's edge cases -- so a refactor of either method
# fails fast without a DSN.

# A mock QueryExecutor: same public shape as DBIO::MySQL::EV::QueryExecutor
# (execute($conn, $sql, $bind) -> Future of raw rows), but replies purely
# from the SQL text -- no fake EV::MariaDB wire to simulate. Records every
# call (which connection, which SQL, which binds) so the pinned-runner
# contract (same $conn for every pinned query) is directly assertable.
{
  package MockExecutor;
  sub new { bless { calls => [], select_rows => undef, next_lii => 42, affected_rows => 1 }, $_[0] }
  sub execute {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{calls} }, { conn => $conn, sql => $sql, bind => [ @{ $bind || [] } ] };

    if ($sql =~ /LAST_INSERT_ID/) {
      return Future->done() unless defined $self->{next_lii};
      return Future->done([ $self->{next_lii} ]);
    }
    if ($sql =~ /^SELECT/) {
      return Future->done(@{ $self->{select_rows} }) if $self->{select_rows};
      return Future->done([ 1, 'row' ]);
    }
    # INSERT/UPDATE/DELETE: affected-rows shape (a plain scalar).
    return Future->done($self->{affected_rows});
  }
}

# A minimal mock OWNER for k193 ("restore select preparation parity"):
# production code wires a real DBIO::MySQL::Storage here through
# DBIO::Storage::DBI::_async_storage. The k193 refactor routes the async
# SELECT path through $owner->_select_args so join pruning / complex-prefetch
# rewriting is not duplicated; tests 12/13 below (select / select_single via
# _run_crud_pinned) hit that path. We supply only the seam the async SELECT
# path now demands (op name first, then the select args the SQLMaker
# consumes) -- we do NOT mirror _assert_async_context_owner, since none of the
# asserts here are context-bound and that seam is exercised end-to-end in
# t/with-context-ownership-mock.t.
{
  package MockOwnerPinned;
  sub new { bless {}, $_[0] }
  sub _select_args { return ('select', @_[1..$#_]) }
}

sub build_storage {
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->{executor} = MockExecutor->new;

  # k193: wire the owning sync storage. As in t/storage-facade-mock.t, hold
  # the owner STRONGLY on the storage itself -- the
  # DBIO::Storage::Async::_owner_storage setter applies weaken(), and an
  # inline `->new` with no other reference weakens to undef by the time the
  # first select_async fires. The upsert block below overrides this with a
  # real DBIO::MySQL::Storage owner (the plan is its method).
  $storage->{_mock_owner} = MockOwnerPinned->new;
  $storage->_owner_storage($storage->{_mock_owner});

  return $storage;
}

my $CONN = bless {}, 'FakeConn';

# =============================================================================
# _run_crud_pinned('insert', ...): the MySQL value-add path -- INSERT then
# SELECT LAST_INSERT_ID() on the SAME pinned connection, never the generic
# one-query SUPER path (which has no way to fetch the auto_increment id).
# =============================================================================

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('insert', $CONN, 'artist', { name => 'Tom' });
  ok $f->is_ready, '_run_crud_pinned(insert) resolves synchronously against the mock';
  my $returned = $f->get;
  is ref $returned, 'HASH', '_run_crud_pinned(insert) resolves a HASHREF (ADR 0031 §3)';
  is_deeply $returned, { name => 'Tom' },
    'hashref carries the supplied insert data (bare table name, no source to introspect)';

  my $calls = $storage->{executor}{calls};
  is scalar(@$calls), 2,
    'insert issues exactly two pinned queries (INSERT + LAST_INSERT_ID) -- '
    . 'NOT the one-query generic SUPER path';
  like $calls->[0]{sql}, qr/^INSERT INTO `artist`/, 'first query is the INSERT';
  is $calls->[1]{sql}, 'SELECT LAST_INSERT_ID()', 'second query reads LAST_INSERT_ID()';
  is $calls->[0]{conn}, $CONN, 'INSERT ran on the supplied pinned connection';
  is $calls->[1]{conn}, $CONN,
    'LAST_INSERT_ID() ran on the SAME pinned connection as the INSERT (not a fresh one)';

  is $storage->last_insert_id, 42,
    'last_insert_id captured from the mocked LAST_INSERT_ID() row';
}

# --- karr #45 regression: the identity_column decision for an upsert is the
# provider storage's, not the SQLMaker's. Core's upsert_async hands this
# backend an on_conflict structure WITHOUT identity_column (that key only
# exists inside the plan DBIO::MySQL::Storage::_mysql_upsert_plan computes
# for the sync path). The ev backend must fold the plan's private keys in
# itself, exactly like the sync insert does -- resolved against the OWNING
# sync storage via the back-ref core wires in _async_storage. Without it the
# rendered UPDATE branch has no `pk` = LAST_INSERT_ID(`pk`) and an upsert
# that hits the UPDATE branch reports the fresh session's LAST_INSERT_ID (0)
# instead of the id of the row the server actually touched.
#
# The real DBIO::Test Artist source is used (not a mini-mock) because the
# plan inspects unique_constraints and columns_info -- and the owner must be
# a real DBIO::MySQL::Storage, because the plan is its method. The mock
# QueryExecutor just answers the two pinned queries (INSERT, LAST_INSERT_ID)
# as before.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $owner  = $schema->storage;
  my $source = $schema->source('Artist');

  my $storage = build_storage;
  $storage->_owner_storage($owner);

  my $f = $storage->_run_crud_pinned(
    'insert', $CONN, $source, { name => 'Tom' },
    { on_conflict => {
        target => 'any', # the only form MySQL can honour; an explicit column
        # target would throw here (Artist has a PK *and* a UNIQUE key)
        action => 'update',
        set    => { name => { -attempted => 'name' } },
    } }
  );
  ok $f->is_ready, 'upsert pinned-run resolves against the mock';
  is_deeply $f->get, { name => 'Tom', artistid => 42 },
    'upsert result: name + the identity the plan resolved (artistid from LII)';

  my $calls = $storage->{executor}{calls};
  is scalar(@$calls), 2,
    'upsert issues exactly two pinned queries (the ODKU INSERT + LAST_INSERT_ID())';
  like $calls->[0]{sql}, qr/`artistid` = LAST_INSERT_ID\(`artistid`\)/,
    'the plan fold reached the SQLMaker: the UPDATE branch carries the identity '
    . 'idiom (karr #45 regression)';
  unlike $calls->[0]{sql}, qr/INSERT INTO `Artist`/,
    'the schema MONIKER never reaches the SQL -- the source is unwrapped via ->name';
}

# --- _insert_returned_columns overlay: source declares an is_auto_increment
# column -- the LII value is folded onto it.

{
  package SourceAutoInc;
  sub new          { bless {}, shift }
  sub name         { 'artist' }
  sub columns      { qw(id name) }
  sub columns_info { { id => { is_auto_increment => 1 }, name => { is_auto_increment => 0 } } }
  sub primary_columns { qw(id) }
}

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('insert', $CONN, SourceAutoInc->new, { name => 'Tom' });
  my $returned = $f->get;
  is_deeply $returned, { name => 'Tom', id => 42 },
    'is_auto_increment column gets the LII value overlaid onto the returned-columns hashref';
}

# --- _auto_increment_column fallback: no is_auto_increment flag anywhere,
# but a PK column that was NOT supplied in the insert data -- matches the
# sync DBIO::Storage::DBI heuristic (server-side auto_increment with no
# schema-declared flag).

{
  package SourcePkFallback;
  sub new          { bless {}, shift }
  sub name         { 'widget' }
  sub columns      { qw(id sku) }
  sub columns_info { { id => { is_auto_increment => 0 }, sku => { is_auto_increment => 0 } } }
  sub primary_columns { qw(id) }
}

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('insert', $CONN, SourcePkFallback->new, { sku => 'WIDGET-1' });
  my $returned = $f->get;
  is_deeply $returned, { sku => 'WIDGET-1', id => 42 },
    'unsupplied PK column gets the LII overlay when no column declares is_auto_increment';
}

# --- _auto_increment_column: when the PK column WAS supplied by the caller
# and nothing declares is_auto_increment, neither branch of the heuristic
# applies -- the hashref must stay exactly the supplied insert data.

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned(
    'insert', $CONN, SourcePkFallback->new, { id => 7, sku => 'WIDGET-2' }
  );
  my $returned = $f->get;
  is_deeply $returned, { id => 7, sku => 'WIDGET-2' },
    'no overlay when the PK was already supplied and no column is flagged is_auto_increment '
    . '(LII silently ignored, exactly like the sync heuristic)';
}

# --- _auto_increment_column: the flagged column is NOT first in ->columns
# order AND is NOT the primary key (so the PK-unsupplied fallback cannot
# accidentally pick the same column and mask a broken flag scan) -- the
# heuristic must find it purely by the is_auto_increment flag.

{
  package SourceFlagNotFirst;
  sub new     { bless {}, shift }
  sub name    { 'ticket' }
  sub columns { qw(uuid seq label) }
  sub columns_info {
    return {
      uuid  => { is_auto_increment => 0 },
      seq   => { is_auto_increment => 1 },
      label => { is_auto_increment => 0 },
    };
  }
  sub primary_columns { qw(uuid) }
}

{
  my $storage = build_storage;
  # uuid (the PK) is supplied, so the PK-unsupplied fallback finds nothing --
  # only the is_auto_increment flag on seq can produce the overlay below.
  my $f = $storage->_run_crud_pinned(
    'insert', $CONN, SourceFlagNotFirst->new, { uuid => 'abc-123', label => 'x' }
  );
  my $returned = $f->get;
  is_deeply $returned, { uuid => 'abc-123', label => 'x', seq => 42 },
    'is_auto_increment column found by flag, not by list position or PK-fallback '
    . '(uuid is the PK and already supplied; seq is flagged but neither first nor PK)';
}

# --- _auto_increment_column: a blessed source with no ->columns capability
# at all short-circuits to "no overlay" rather than dying.

{
  package SourceNoColumns;
  sub new  { bless {}, shift }
  sub name { 'blob' }
}

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('insert', $CONN, SourceNoColumns->new, { data => 'x' });
  my $returned = $f->get;
  is_deeply $returned, { data => 'x' },
    'a source without ->columns is left unintrospected -- hashref is just the insert data';
}

# =============================================================================
# _insert_returned_columns edge cases, called directly: defensive shapes for
# the LII row the pinned SELECT LAST_INSERT_ID() query can hand back.
# =============================================================================

{
  my $storage = build_storage;
  my $source  = SourceAutoInc->new;
  my %to_insert = (name => 'Tom');

  is_deeply $storage->_insert_returned_columns($source, { %to_insert }, undef),
    { %to_insert }, 'undef LII row: hashref is the insert data, unchanged';

  is_deeply $storage->_insert_returned_columns($source, { %to_insert }, []),
    { %to_insert }, 'empty-arrayref LII row: hashref is the insert data, unchanged';

  is_deeply $storage->_insert_returned_columns($source, { %to_insert }, [ undef ]),
    { %to_insert }, 'LII row with an undef id: hashref is the insert data, unchanged';

  is_deeply $storage->_insert_returned_columns($source, { %to_insert }, 'not-an-arrayref'),
    { %to_insert }, 'non-arrayref LII row: hashref is the insert data, unchanged (defensive)';
}

# =============================================================================
# _run_crud_pinned for every non-insert op: MUST delegate to core's generic
# SUPER runner (one pinned query, no LAST_INSERT_ID() special-case). This is
# the routing TransactionContext relies on for select/select_single/update/
# delete inside a transaction -- t/transaction-context.t mocks
# _run_crud_pinned as an opaque black box, so it never exercises this
# class's actual implementation of the non-insert branch.
# =============================================================================

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('select', $CONN, 'artist', '*', { id => 1 });
  ok $f->is_ready, "_run_crud_pinned(select) resolves against the mock";
  my @rows = $f->get;
  is_deeply \@rows, [ [ 1, 'row' ] ], 'select resolves the raw row list';

  my $calls = $storage->{executor}{calls};
  is scalar(@$calls), 1,
    'select issues exactly one pinned query -- delegates to the generic SUPER runner, '
    . 'no MySQL LAST_INSERT_ID() special-case';
  like $calls->[0]{sql}, qr/^SELECT \* FROM `artist`/, 'query is a plain SELECT';
  is $calls->[0]{conn}, $CONN, 'select ran on the supplied pinned connection';
}

{
  my $storage = build_storage;
  $storage->{executor}{select_rows} = [ [ 1, 'row' ], [ 2, 'row2' ] ];
  my $f = $storage->_run_crud_pinned('select_single', $CONN, 'artist', '*', { id => 1 });
  ok $f->is_ready, '_run_crud_pinned(select_single) resolves against the mock';
  my $row = $f->get;
  is_deeply $row, [ 1, 'row' ],
    'select_single extracts only the first row (core generic post-processing, '
    . 'reached via SUPER delegation)';
  is scalar(@{ $storage->{executor}{calls} }), 1,
    'select_single issues exactly one pinned query';
}

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('update', $CONN, 'artist', { name => 'X' }, { id => 1 });
  ok $f->is_ready, '_run_crud_pinned(update) resolves against the mock';
  my $count = $f->get;
  is $count, 1, 'update resolves the affected-row count';

  my $calls = $storage->{executor}{calls};
  is scalar(@$calls), 1, 'update issues exactly one pinned query';
  like $calls->[0]{sql}, qr/^UPDATE `artist`/, 'query is an UPDATE';
  is $calls->[0]{conn}, $CONN, 'update ran on the supplied pinned connection';
}

{
  my $storage = build_storage;
  my $f = $storage->_run_crud_pinned('delete', $CONN, 'artist', { id => 1 });
  ok $f->is_ready, '_run_crud_pinned(delete) resolves against the mock';
  my $count = $f->get;
  is $count, 1, 'delete resolves the affected-row count';

  my $calls = $storage->{executor}{calls};
  is scalar(@$calls), 1, 'delete issues exactly one pinned query';
  like $calls->[0]{sql}, qr/^DELETE FROM `artist`/, 'query is a DELETE';
  is $calls->[0]{conn}, $CONN, 'delete ran on the supplied pinned connection';
}

done_testing;

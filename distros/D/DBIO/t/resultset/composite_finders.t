use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# The audit 2026-07-20 found the sync composite finders
# find_or_create / find_or_new / update_or_new grazed only as a side effect of
# t/resultset/async_parity_helpers.t's sync/async parity checks (real coverage
# only existed for real storage, in dbio-sqlite). Sibling update_or_create
# already has dedicated ADR-0034 coverage in
# t/resultset/update_or_create_related.t -- this file gives its three
# siblings the same dedicated, mock-only treatment: the found branch, the
# not-found branch, the C<key => $constraint> selection path, and the
# documented POD examples/idioms for each. Everything runs on
# DBIO::Test::Storage -- no real DB.
#
# Unlike update_or_create/update_or_create_async, find_or_create, find_or_new
# and update_or_new all hand their condition straight to find() as-is -- none
# of them run it through _find_lookup_cond, so there is no ADR 0034
# relation-valued-key dropping to exercise here (update_or_new_async's own
# POD note calls this out explicitly for its sync counterpart).
#
# Schema note: the POD for these three methods carries example column/
# constraint names ('artist', 'artists') inherited from DBIx::Class's own
# generic docs; DBIO::Test::Schema::Artist's real columns are
# artistid/name/rank/charfield with named unique constraints 'primary',
# 'artist_name' (name), 'artist_artistid' (artistid) and 'u_nullable'. The tests below
# use the schema's real column/constraint names while preserving the
# documented semantics (searching by a unique constraint that is not the
# primary key). CD's 'cd_artist_title' constraint (artist+title) matches the
# POD text verbatim, EXCEPT the POD's example 'artist' value is a string
# ('Massive Attack') -- in this schema 'artist' is CD's integer belongs_to FK
# column, so a string there trips "isn't numeric" under C<use warnings> when
# the row layer diffs old vs new value; a plain integer artist id is used
# instead, preserving the constraint-search semantics without that warning.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# Columns are returned positionally by the mock cursor, so mock rows must
# match add_columns() order.
#   Artist: artistid, name, rank, charfield
#   CD:     cdid, artist, title, year, genreid, single_track
#
# CD's table name is a scalar ref (\'cd', see DBIO::Test::Schema::CD) -- on
# purpose, to test raw-SQL table names -- so its generated SQL carries an
# UNQUOTED "cd", unlike Artist's quoted "artist". Mocks/regexes below account
# for that.

# helper: pull captured ops as a compact list of "op:table" strings
sub op_tables {
  map {
    my $t = $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?(\w+)"?/i ? $1 : '?';
    "$_->{op}:$t"
  } $storage->captured_queries;
}

# ==============================================================================
# find_or_create
# ==============================================================================

# --- (a) found branch: the existing row is returned, nothing is inserted ----
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM "artist"/i, [[ 1, 'Miles Davis', 13, undef ]]);

  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->find_or_create(
      { artistid => 1, name => 'Miles Davis' },
      { key => 'primary' },
    );
  } 'find_or_create (row present) lives';

  isa_ok $row, 'DBIO::Row', 'returned row';
  ok $row->in_storage, 'the found row is in_storage';
  is $row->name, 'Miles Davis', 'resolves with the storage row';

  is_deeply [ op_tables() ], [ 'select:artist' ],
    'find_or_create found the row via a single SELECT and never wrote anything';
}

# --- (b) not-found branch: a new row is created and returned ----------------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # no mock -> find() misses -> new_result(...)->insert
  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->find_or_create(
      { artistid => 99, name => 'Brand New' },
      { key => 'primary' },
    );
  } 'find_or_create (row absent) lives';

  ok $row->in_storage, 'the freshly created row is in_storage';
  is $row->name, 'Brand New', 'carries the supplied data';

  is_deeply [ op_tables() ], [ 'select:artist', 'insert:artist' ],
    'find_or_create missed on the SELECT, then INSERTed the new row';
}

# POD contrast: find_or_create's own "Note" says you don't need in_storage to
# tell found from created -- both branches above return an in_storage row.
# (a)/(b) demonstrate exactly that; find_or_new below is the one that leaves
# you to check in_storage yourself.

# --- (c)/(d) key => <constraint>: POD's literal CD/cd_artist_title example --
# "my $cd = $schema->resultset('CD')->find_or_create({ artist => ...,
#  title => ... }, { key => 'cd_artist_title' })" -- searches on the named
# unique constraint, not the primary key (no 'cdid' anywhere in the lookup).
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM cd "me"/i, [[ 5, 1, 'Mezzanine', 1998, undef, undef ]]);

  my $row = $schema->resultset('CD')->find_or_create(
    { artist => 1, title => 'Mezzanine' },
    { key => 'cd_artist_title' },
  );

  ok $row->in_storage, 'found via the named constraint, in_storage';
  is $row->title, 'Mezzanine', 'resolves with the storage row';

  my ($select) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $select, 'find_or_create ran a SELECT';
  my ($where) = $select->{sql} =~ /WHERE\s*\((.*)\)/;
  like $where, qr/"artist"\s*=\s*\?.*"title"\s*=\s*\?|"title"\s*=\s*\?.*"artist"\s*=\s*\?/,
    'the lookup used the artist+title constraint columns';
  unlike $where, qr/"cdid"/, 'the lookup never referenced the primary key column';

  is_deeply [ op_tables() ], [ 'select:cd' ],
    'no write happened -- the row was found via the named constraint alone';
}
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # no mock -> the named constraint also misses cleanly -> INSERT
  my $row = $schema->resultset('CD')->find_or_create(
    { artist => 1, title => 'Brand New CD', year => 2020 },
    { key => 'cd_artist_title' },
  );

  ok $row->in_storage, 'created via the named-constraint not-found branch';
  is_deeply [ op_tables() ], [ 'select:cd', 'insert:cd' ],
    'find_or_create missed under the named constraint, then INSERTed';
}

# --- (e) key => <constraint> the condition cannot satisfy: throws -----------
# Shared find() semantics (POD: "an undefined... may skew your search" / "DBIO
# is unable to construct a query that satisfies the named unique constraint
# fully... an exception is thrown"). find_or_new and update_or_new below
# share this exact code path (both hand $attrs straight to find()), so this
# is exercised once here rather than duplicated per method.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  throws_ok {
    $schema->resultset('CD')->find_or_create(
      { title => 'Mezzanine' }, # 'artist' missing -> constraint unsatisfiable
      { key => 'cd_artist_title' },
    );
  } qr/Unable to satisfy requested constraint 'cd_artist_title'.*'artist'/,
    'an unsatisfiable key constraint throws instead of silently searching something else';

  ok( !( grep { $_->{op} eq 'select' } $storage->captured_queries ),
    'no SELECT was issued -- the bad constraint never reached storage' );
}

# ==============================================================================
# find_or_new
# ==============================================================================

# --- (f) found branch: the existing row is returned, nothing is inserted ----
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM "artist"/i, [[ 1, 'Wayne Shorter', 13, undef ]]);

  my $row = $schema->resultset('Artist')->find_or_new(
    { artistid => 1, name => 'Wayne Shorter' },
    { key => 'primary' },
  );

  ok $row->in_storage, 'the found row is in_storage';
  is $row->name, 'Wayne Shorter', 'resolves with the storage row';
  is_deeply [ op_tables() ], [ 'select:artist' ],
    'find_or_new found the row via a single SELECT and never wrote anything';
}

# --- (g) not-found branch: an uninserted result is returned -- the documented
# POD idiom is "if (!$cd->in_storage) { $cd->insert }" ----------------------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  my $row = $schema->resultset('Artist')->find_or_new(
    { artistid => 55, name => 'Nobody Yet' },
    { key => 'primary' },
  );

  ok !$row->in_storage, 'the new row is NOT in_storage -- unlike find_or_create';
  is $row->name, 'Nobody Yet', 'carries the supplied data';
  is_deeply [ op_tables() ], [ 'select:artist' ],
    'find_or_new only SELECTed -- no INSERT happened on its own';

  # follow the documented idiom through to completion
  $storage->reset_captured;
  $row->insert;
  ok $row->in_storage, 'after the documented $row->insert call, the row is now in_storage';
  is_deeply [ op_tables() ], [ 'insert:artist' ],
    'the deferred INSERT only fires once the caller explicitly asks for it';
}

# --- (h)/(i) key => <constraint>: adapted from the POD's Artist example -----
# POD (generic DBIx::Class schema): find_or_new({ artist => 'fred' },
#  { key => 'artists' }) -- adapted to this schema's real column ('name') and
# real non-primary unique constraint ('artist_name'), preserving the
# documented point: searching by a unique constraint that is not the primary
# key.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM "artist"/i, [[ 2, 'fred', 13, undef ]]);

  my $row = $schema->resultset('Artist')->find_or_new(
    { name => 'fred' },
    { key => 'artist_name' },
  );

  ok $row->in_storage, 'found via the named (non-primary) constraint';
  is $row->name, 'fred', 'resolves with the storage row';

  my ($select) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  my ($where) = $select->{sql} =~ /WHERE\s*\((.*)\)/;
  like $where, qr/"name"\s*=\s*\?/, 'the lookup used the name column';
  unlike $where, qr/"artistid"/, 'the lookup never referenced the primary key column';
}
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # no mock -> the named constraint misses -> uninserted new_result, no INSERT
  my $row = $schema->resultset('Artist')->find_or_new(
    { name => 'ghost' },
    { key => 'artist_name' },
  );

  ok !$row->in_storage, 'not found under the named constraint -- uninserted result';
  is $row->name, 'ghost', 'carries the supplied data';
  is_deeply [ op_tables() ], [ 'select:artist' ],
    'only the SELECT under the named constraint ran -- no INSERT';
}

# ==============================================================================
# update_or_new
# ==============================================================================

# --- (j) found branch: the existing row is updated in place -----------------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM "artist"/i, [[ 1, 'Old Name', 13, undef ]]);

  my $row = $schema->resultset('Artist')->update_or_new(
    { artistid => 1, name => 'New Name' },
    { key => 'primary' },
  );

  ok $row->in_storage, 'the updated row is in_storage';
  is $row->name, 'New Name', 'the row carries the updated value';

  is_deeply [ op_tables() ], [ 'select:artist', 'update:artist' ],
    'update_or_new found the row via SELECT, then UPDATEd it';
  ok( !( grep { $_->{op} eq 'txn_begin' } $storage->captured_queries ),
    'no transaction is opened for a plain Artist update (no cascade_update relations)' );
}

# --- (k) not-found branch: an uninserted result is returned -- the documented
# POD idiom is "if ($cd->in_storage) {...} else { $cd->insert }" -----------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  my $row = $schema->resultset('Artist')->update_or_new(
    { artistid => 77, name => 'Not Yet Signed' },
    { key => 'primary' },
  );

  ok !$row->in_storage, 'the new row is NOT in_storage';
  is $row->name, 'Not Yet Signed', 'carries the supplied data';
  is_deeply [ op_tables() ], [ 'select:artist' ],
    'update_or_new only SELECTed on a miss -- no UPDATE, no INSERT';

  # follow the documented idiom through to completion
  $storage->reset_captured;
  $row->insert;
  ok $row->in_storage, 'after the documented $row->insert call, the row is now in_storage';
  is_deeply [ op_tables() ], [ 'insert:artist' ],
    'the deferred INSERT only fires once the caller explicitly asks for it';
}

# --- (l)/(m) key => <constraint>: POD's literal CD/cd_artist_title example --
{
  $storage->clear_mocks;
  $storage->reset_captured;

  $storage->mock(qr/FROM cd "me"/i, [[ 5, 1, 'Mezzanine', 1998, undef, undef ]]);

  # 'year' differs from the mocked row (1998) so the row layer actually has a
  # dirty column to write; 'artist'+'title' match the mocked row exactly, so
  # the lookup is what finds it under the named constraint.
  my $row = $schema->resultset('CD')->update_or_new(
    { artist => 1, title => 'Mezzanine', year => 1999 },
    { key => 'cd_artist_title' },
  );

  ok $row->in_storage, 'found via the named constraint, in_storage';
  is $row->year, 1999, 'the row carries the updated value';

  my ($select) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  my ($where) = $select->{sql} =~ /WHERE\s*\((.*)\)/;
  unlike $where, qr/"cdid"/, 'the lookup never referenced the primary key column';
  ok( ( grep { $_->{op} eq 'update' } $storage->captured_queries ),
    'the found row was UPDATEd' );
}
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # no mock -> the named constraint misses -> uninserted new_result, no write
  my $row = $schema->resultset('CD')->update_or_new(
    { artist => 1, title => 'Yet Another New CD', year => 2022 },
    { key => 'cd_artist_title' },
  );

  ok !$row->in_storage, 'not found under the named constraint -- uninserted result';
  is $row->title, 'Yet Another New CD', 'carries the supplied data';
  is_deeply [ op_tables() ], [ 'select:cd' ],
    'only the SELECT under the named constraint ran -- no UPDATE, no INSERT';
}

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# ADR 0033: update_or_create() DWIM-splits a mixed condition that carries a
# nested related sub-hash. The main row is found/updated/created from the plain
# columns; each unresolvable relation sub-hash is applied via its own
# update_or_create on the related resultset AFTER the main row exists. The main
# 'key' constraint applies only to the main table. Everything runs on the mock
# storage -- no real DB.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# Columns are returned positionally by the mock cursor, so mock rows must match
# add_columns() order.
#   Artist: artistid, name, rank, charfield
#   CD:     cdid, artist, title, year, genreid, single_track

# helper: pull captured ops as a compact list of "op:table" strings
sub op_tables {
  map {
    my $t = $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?(\w+)"?/i ? $1 : '?';
    "$_->{op}:$t"
  } $storage->captured_queries;
}

# --- (a) main row exists, relation differs -> both updated, no exception ------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # main-table find() returns an existing artist with a DIFFERENT name
  $storage->mock_persistent(qr/FROM "artist"/i, [[ 1, 'Old Name', 13, undef ]]);
  # related-table find() returns an existing cd with a DIFFERENT title/year
  $storage->mock_persistent(qr/FROM cd\b/i, [[ 10, 1, 'Old Title', 1999, undef, undef ]]);

  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->update_or_create(
      {
        artistid => 1,
        name     => 'Updated Name',
        cds      => { title => 'New Title', year => 2020 },
      },
      { key => 'primary' },
    );
  } 'has_many sub-hash no longer throws "Complex condition" from update_or_create';

  isa_ok $row, 'DBIO::Row', 'returned main row';

  my @ops = op_tables();
  ok( ( grep { $_ eq 'select:artist' } @ops ), 'find() ran a SELECT on the main table' );
  ok( ( grep { $_ eq 'update:artist' } @ops ), 'main row was UPDATEd (name differed)' );
  ok( ( grep { $_ eq 'select:cd' } @ops ),     'relation was searched on its own resultset' );
  ok( ( grep { $_ eq 'update:cd' } @ops ),     'existing related row was UPDATEd (differed)' );
}

# --- (b) 'key' constraint is applied to the main table only ------------------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # key => 'artist_name' is a real unique constraint on Artist (auto-named from
  # add_unique_constraint(['name'])), but there is NO such constraint on CD. If
  # it leaked into the related update_or_create, CD's find() would die with
  # "Unknown unique constraint name". It must not.
  $storage->mock_persistent(qr/FROM "artist"/i, [[ 5, 'Bowie', 13, undef ]]);
  # no cd mock -> related find() misses -> related row is INSERTed

  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->update_or_create(
      {
        name => 'Bowie',
        cds  => { title => 'Low', year => 1977 },
      },
      { key => 'artist_name' },
    );
  } "main-table 'key' does not leak into the related resultset";

  my @ops = op_tables();
  ok( ( grep { $_ eq 'select:artist' } @ops ), "main find() used the 'artist_name' constraint" );
  ok( ( grep { $_ eq 'select:cd' } @ops ),     'related resultset was searched (no key)' );
  ok( ( grep { $_ eq 'insert:cd' } @ops ),     'missing related row was INSERTed' );

  # sharpen: the related SELECT must not mention the artist-only 'name' column
  my ($cd_select) = grep { $_->{op} eq 'select' && $_->{sql} =~ /FROM cd\b/i }
    $storage->captured_queries;
  ok $cd_select, 'captured the related cd SELECT';
  unlike $cd_select->{sql}, qr/\bname\b/i,
    'related SELECT was scoped by FK+heuristics, not the main-table constraint';
}

# --- (c) main row absent -> insert main, then upsert the relation ------------
{
  $storage->clear_mocks;
  $storage->reset_captured;

  # no artist mock  -> main find() misses -> main row INSERTed
  # no cd mock      -> related find() misses -> related row INSERTed
  my $row;
  lives_ok {
    $row = $schema->resultset('Artist')->update_or_create(
      {
        artistid => 99,
        name     => 'Brand New',
        cds      => { title => 'Debut', year => 2001 },
      },
      { key => 'primary' },
    );
  } 'insert path with a split-out relation lives';

  my @ops = op_tables();
  ok( ( grep { $_ eq 'insert:artist' } @ops ), 'main row INSERTed' );
  ok( ( grep { $_ eq 'select:cd' } @ops ),     'relation searched after main insert' );
  ok( ( grep { $_ eq 'insert:cd' } @ops ),     'related row INSERTed' );

  # a split-out relation runs the whole thing in a transaction (multi-create parity)
  ok( ( grep { $_->{op} eq 'txn_begin' } $storage->captured_queries ),
    'split relation is wrapped in a transaction' );
  ok( ( grep { $_->{op} eq 'txn_commit' } $storage->captured_queries ),
    'transaction committed' );
}

# --- (d) regression: find()'s complex-condition guard still fires ------------
# The DWIM lives in update_or_create; a *direct* find() with a genuinely
# crosstable relation sub-hash (here a coderef-cond has_many that cannot be
# reduced to a join-free condition on the main table) must still be rejected
# exactly as before.
{
  $storage->clear_mocks;
  $storage->reset_captured;

  throws_ok {
    $schema->resultset('Artist')->find({ artistid => 1, cds_cref_cond => { title => 'x' } });
  } qr/Complex condition via relationship 'cds_cref_cond' is unsupported in find\(\)/,
    "find() still guards genuinely crosstable relation sub-hashes";
}

# --- (e) split logic: belongs_to FK folds into main, has_many is peeled ------
# belongs_to supplied as a resolvable FK is NOT split (it resolves to a plain
# column on the main table); has_many/might_have IS split.
{
  my $cd_rs = $schema->resultset('CD');
  my ($main, $rel) = $cd_rs->_split_related_update_conds({
    cdid   => 1,
    title  => 'X',
    artist => { artistid => 7 },              # belongs_to, FK-resolvable
    tracks => { title => 'T', position => 1 },# has_many, crosstable
  });

  ok exists $main->{cdid},   'plain column stays in main cond';
  ok exists $main->{title},  'plain column stays in main cond';
  ok exists $main->{artist}, 'resolvable belongs_to stays in main cond (not split)';
  ok !exists $main->{tracks},'has_many is removed from main cond';

  is_deeply [ sort keys %$rel ], ['tracks'],
    'only the unresolvable has_many is peeled into the related subconds';
  is_deeply $rel->{tracks}, { title => 'T', position => 1 },
    'peeled sub-hash is carried through verbatim';
}

done_testing;

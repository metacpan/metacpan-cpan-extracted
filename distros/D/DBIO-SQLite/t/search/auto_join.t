use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;

# Test auto-discovery of joins from search condition keys.
# When a search condition references a relationship via dotted notation
# (e.g. 'artist.name'), the required join should be added automatically
# without the user needing to specify { join => 'artist' }.

my $schema = DBIO::SQLite::Test->init_schema;

# Test data from populate_schema:
#   Artist 1 (Caterwauler McCrae) -> CDs 1,2,3
#   Artist 2 (Random Boy Band)    -> CD 4
#   Artist 3 (We Are Goth)        -> CD 5
#   CD 1 -> Tracks 16,17,18
#   CD 2 -> Tracks 4,5,6
#   etc.

# --- belongs_to auto-join ---
{
  my @cds = $schema->resultset('CD')->search(
    { 'artist.name' => 'Caterwauler McCrae' }
  )->all;
  is(scalar @cds, 3, 'auto-join belongs_to: found 3 CDs');
}

# --- has_many auto-join ---
{
  my @cds = $schema->resultset('CD')->search(
    { 'tracks.title' => 'Boring Name' }
  )->all;
  is(scalar @cds, 1, 'auto-join has_many: found 1 CD');
}

# --- count works with auto-join ---
{
  my $count = $schema->resultset('CD')->search(
    { 'artist.name' => 'Caterwauler McCrae' }
  )->count;
  is($count, 3, 'auto-join works with count');
}

# --- chained search preserves auto-join ---
{
  my $rs = $schema->resultset('CD')->search(
    { 'artist.name' => 'Caterwauler McCrae' }
  );
  my @cds = $rs->search({ year => { '>' => 1998 } })->all;
  is(scalar @cds, 2, 'chained search with auto-join');
}

# --- explicit join still works ---
{
  my @cds = $schema->resultset('CD')->search(
    { 'artist.name' => 'Caterwauler McCrae' },
    { join => 'artist' },
  )->all;
  is(scalar @cds, 3, 'explicit join still works');
}

# --- me.column does not trigger auto-join ---
{
  my @cds = $schema->resultset('CD')->search(
    { 'me.title' => 'Spoonful of bees' }
  )->all;
  is(scalar @cds, 1, 'me.column does not trigger auto-join');
}

# --- non-relationship dotted name does not crash ---
{
  my $rs = $schema->resultset('CD')->search(
    { 'nonexistent.column' => 'foo' }
  );
  # Should not auto-join (nonexistent is not a relationship)
  # The query will use the condition as-is; it may fail at DB level
  # but should not throw during ResultSet construction
  ok(defined $rs, 'non-relationship dotted name does not crash RS construction');
}

# --- multiple auto-joins ---
{
  my @cds = $schema->resultset('CD')->search(
    {
      'artist.name' => 'Caterwauler McCrae',
      'tags.tag'    => 'Blue',
    },
  )->all;
  is(scalar @cds, 3, 'multiple auto-joins in one search');
}

done_testing;

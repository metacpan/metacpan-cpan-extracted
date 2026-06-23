use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;

# This test verifies that HAVING clauses with bind parameters return
# correct results. SQLite (and potentially other backends) binds all
# parameters as TEXT by default, which breaks comparisons against
# integer aggregate results due to cross-type comparison rules
# (e.g. INTEGER > TEXT is always FALSE in SQLite).
#
# DBIO's SQLite storage layer fixes this by auto-hinting numeric
# bind values as SQL_INTEGER. This test ensures the fix works and
# catches regressions on any backend.

my $schema = DBIO::SQLite::Test->init_schema(
  dsn => 'dbi:SQLite::memory:',
);

# Test data from populate_schema:
#   Artist 1 (Caterwauler McCrae) -> CDs 1,2,3 -> 3 tracks each = 9 tracks
#   Artist 2 (Random Boy Band)    -> CD 4       -> 3 tracks      = 3 tracks
#   Artist 3 (We Are Goth)        -> CD 5       -> 3 tracks      = 3 tracks

# --- HAVING with literal condition + bind operator ---
# Note: hashref keys like { 'COUNT(tracks.trackid)' => ... } do not work
# with quote_names because SQL::Abstract treats the key as an identifier
# and quotes the dot as a separator: "COUNT(tracks"."trackid)".
# Use literal SQL for function calls in HAVING.
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    join     => { cds => 'tracks' },
    group_by => ['me.artistid', 'me.name'],
    having   => \[ 'COUNT("tracks"."trackid") > ?', 3 ],
  });
  my @artists = $rs->all;
  is(scalar @artists, 1, 'HAVING with literal+bind operator: 1 artist with > 3 tracks');
  is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+bind operator: correct artist')
    if @artists;
}

# --- HAVING with literal SQL + bind parameter ---
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    join     => { cds => 'tracks' },
    group_by => ['me.artistid', 'me.name'],
    having   => \[ 'COUNT(tracks.trackid) > ?', 3 ],
  });
  my @artists = $rs->all;
  is(scalar @artists, 1, 'HAVING with literal+bind: 1 artist with > 3 tracks');
  is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+bind: correct artist')
    if @artists;
}

# --- HAVING with literal SQL + typed bind parameter ---
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    join     => { cds => 'tracks' },
    group_by => ['me.artistid', 'me.name'],
    having   => \[ 'COUNT(tracks.trackid) > ?', [ {}, 3 ] ],
  });
  my @artists = $rs->all;
  is(scalar @artists, 1, 'HAVING with literal+typed bind: 1 artist with > 3 tracks');
  is($artists[0]->name, 'Caterwauler McCrae', 'HAVING with literal+typed bind: correct artist')
    if @artists;
}

# --- HAVING with equality (also affected by type mismatch) ---
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    join     => { cds => 'tracks' },
    group_by => ['me.artistid', 'me.name'],
    having   => \[ 'COUNT(tracks.trackid) = ?', 3 ],
  });
  my @artists = sort { $a->artistid <=> $b->artistid } $rs->all;
  is(scalar @artists, 2, 'HAVING with = bind: 2 artists with exactly 3 tracks');
}

# --- HAVING with literal SQL (no bind, sanity check) ---
{
  my $rs = $schema->resultset('Artist')->search(undef, {
    join     => { cds => 'tracks' },
    group_by => ['me.artistid', 'me.name'],
    having   => \[ 'COUNT(tracks.trackid) > 3' ],
  });
  my @artists = $rs->all;
  is(scalar @artists, 1, 'HAVING with literal (no bind): 1 artist with > 3 tracks');
}

done_testing;

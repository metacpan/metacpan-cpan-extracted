use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

# --- correlate: basic correlated subquery ---
{
  my $artist_rs = $schema->resultset('Artist');

  # Use correlate to add a correlated subquery counting CDs per artist
  my $with_cd_count = $artist_rs->search(undef, {
    '+columns' => {
      cd_count => $artist_rs->correlate('cds')->count_rs->as_query
    }
  });

  isa_ok($with_cd_count, 'DBIO::ResultSet', 'correlate in subquery returns RS');

  my @rows = $with_cd_count->hri->all;
  ok(@rows > 0, 'correlate query returns rows');
  ok(exists $rows[0]->{cd_count}, 'correlated count column exists');

  # Verify the counts make sense
  for my $row (@rows) {
    my $actual = $schema->resultset('CD')->search({
      artist => $row->{artistid}
    })->count;
    is($row->{cd_count}, $actual,
      "correlate cd_count for artist $row->{artistid} matches actual count");
  }
}

# --- correlate: correlated subquery for filtering ---
{
  my $artist_rs = $schema->resultset('Artist');

  # Find artists who have at least 1 CD
  my $corr = $artist_rs->correlate('cds');
  my $has_cds = $artist_rs->search(undef, {
    '+columns' => {
      has_cd => $corr->count_rs->as_query,
    }
  })->hri;

  my @rows = $has_cds->all;
  ok(@rows > 0, 'correlated filter query works');
}

# --- correlate: different relationships ---
{
  my $cd_rs = $schema->resultset('CD');

  # Correlate with tracks
  my $with_track_count = $cd_rs->search(undef, {
    '+columns' => {
      track_count => $cd_rs->correlate('tracks')->count_rs->as_query
    }
  });

  my @rows = $with_track_count->hri->all;
  ok(@rows > 0, 'correlate with tracks returns rows');
  ok(exists $rows[0]->{track_count}, 'correlated track_count exists');
}

# --- correlate: bad relationship name ---
{
  my $rs = $schema->resultset('CD');
  throws_ok {
    $rs->correlate('nonexistent_rel')
  } qr/No such relationship/, 'correlate with bad rel throws';
}

# --- explain ---
{
  my $rs = $schema->resultset('CD');
  my $plan = $rs->explain;

  is(ref $plan, 'ARRAY', 'explain returns arrayref');
  ok(@$plan > 0, 'explain has query plan rows');

  # explain with search conditions
  my $filtered = $rs->search({ year => 1999 });
  my $fplan = $filtered->explain;
  is(ref $fplan, 'ARRAY', 'explain on filtered RS returns arrayref');
  ok(@$fplan > 0, 'filtered explain has rows');
}

# --- explain: complex query ---
{
  my $rs = $schema->resultset('CD')->search(
    { 'artist.name' => { '!=' => undef } },
    { join => 'artist', order_by => 'me.year' }
  );

  my $plan = $rs->explain;
  is(ref $plan, 'ARRAY', 'explain on joined query returns arrayref');
}

# --- search_or ---
{
  my $rs = $schema->resultset('CD');
  my $spoon = $rs->search({ title => { -like => '%Spoon%' } });
  my $old = $rs->search({ year => { '<' => 2000 } });

  my $combined = $rs->search_or([$spoon, $old]);
  isa_ok($combined, 'DBIO::ResultSet', 'search_or returns RS');

  my @rows = $combined->all;
  for my $row (@rows) {
    ok(
      $row->title =~ /Spoon/ || $row->year < 2000,
      'search_or row matches at least one condition'
    );
  }
}

# --- search_or: error with different sources ---
{
  my $cd_rs = $schema->resultset('CD');
  my $artist_rs = $schema->resultset('Artist');

  throws_ok {
    $cd_rs->search_or([$artist_rs])
  } qr/same result_source/, 'search_or with different sources throws';
}

done_testing;

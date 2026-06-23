use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Test how related_resultset and set_cache interact

for my $i (0, 1) {

  # We do this twice for comparison.
  #
  # The first time we will just set the cache and get the related resultset.
  #
  # The second time we will additionally get $cd_rset->related_resultset('artist') first.
  #
  # In 0.082840, however, this has the undesirable effect that even after set_cache is called,
  # subsequent calls to $cd_rset->related_resultset('artist') reuse the previously generated resultset,
  # instead of returning a resultset with the items from the cache.

  my @tracks = $schema->resultset('Track')->search({ title => 'Apiary' });

  my $cd_rset = $tracks[0]->related_resultset('cd');

  my @cds = $schema->resultset('CD')->search({ cdid => 1 }, { prefetch => 'artist' });

  my ($artist_rset_before, $artist_rset_after);

  if ($i) {
    $artist_rset_before = $cd_rset->related_resultset('artist');
  }

  $cd_rset->set_cache(\@cds);

  $artist_rset_after = $cd_rset->related_resultset('artist');

  is scalar $cd_rset, 1, 'Track should belong to a CD';
  is scalar @{ $cd_rset->get_cache || [] }, 1, 'CD cache should contain one item';

  is scalar $cd_rset->related_resultset('artist'), 1, 'Track should belong to an Artist';

  # The following fails when DBIO::ResultSet::set_cache does not clear related resultsets
  is scalar @{ $artist_rset_after->get_cache || [] }, 1, 'Artist cache should contain one item';
}

done_testing;

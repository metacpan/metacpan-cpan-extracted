#!perl 
use strict;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 33;

use lib 't/lib';

use_ok('DBArtists');

# no where
{ 
  is DBArtists->max('cds.price'),  2500, 'SELECT MAX(price) FROM cds';
  is DBArtists->min('cds.price'),   800, 'SELECT MIN(price) FROM cds';
  is DBArtists->sum('cds.price'), 10000, 'SELECT SUM(price) FROM cds';
  is DBArtists->counter('cds.*'),     7, 'SELECT COUNT(*)   FROM cds';
}

# distinct
{
  is DBCDs    ->counter('distinct artist'),     5,
  		'SELECT COUNT (DISTINCT artist) FROM cds';
  is DBArtists->counter('distinct cds.artist'), 5,
  		'SELECT COUNT (DISTINCT artist) FROM cds';

  is DBCDs    ->sum('distinct artist'),     15,
  		'SELECT SUM (DISTINCT artist) FROM cds';
  is DBArtists->sum('distinct cds.artist'), 15,
  		'SELECT COUNT (DISTINCT artist) FROM cds';
}


# where
{
  is DBArtists->max('cds.price', name => 'foo'), 1200,
  	'SELECT MAX(cds.price) FROM artists me, cds WHERE me.name = "foo"';
  is DBArtists->min('cds.price', name => 'foo'), 1000,
  	'SELECT MIN(cds.price) FROM artists me, cds WHERE me.name = "foo"';
  is DBArtists->sum('cds.price', name => 'foo'), 3400,
  	'SELECT MIN(cds.price) FROM artists me, cds WHERE me.name = "foo"';
  is DBArtists->counter('cds.*', name => 'foo'),    3,
  	'SELECT MIN(cds.price) FROM artists me, cds WHERE me.name = "foo"';
}

# single artist
{
  my ($artist) = DBArtists->search( name => 'foo' );
  is $artist->max('cds.price'), 1200, "foo's max price";
  is $artist->min('cds.price'), 1000, "foo's max price";
  is $artist->sum('cds.price'), 3400, "foo's max price";
  is $artist->counter('cds.*'), 3, "foo's max price";
}

# search with
{
  my @artists = DBArtists->search_with_max('cds.price',
  	name => [qw/foo bar baz/],
  );
  is scalar @artists, 3, "WHERE artists.name IN ('foo', 'bar', 'baz')";
  for (@artists) {
    my $artist = DBArtists->retrieve( $_->id );
    is $_->max, $artist->max('cds.price'), "match MAX(cds.price) [".$_->name."]";
  }
}
{
  my @artists = DBArtists->search_with_sum('cds.price',
  	age => {'<=', 25},
  );
  is scalar @artists, 3, "WHERE artists.age <= 25";
  for (@artists) {
    my $artist = DBArtists->retrieve( $_->id );
    is $_->sum, $artist->sum('cds.price'), "match SUM(cds.price) [".$_->name."]";
  }
}
{
  my @artists = DBArtists->search_with_counter('cds.*',
  	'label.name' => 'eng',
  );
  is scalar @artists, 3, "WHERE artists.label.name = 'eng'";
  for (@artists) {
    my $artist = DBArtists->retrieve( $_->id );
    is $_->counter, $artist->counter('cds.*'), "match COUNT(cds.*) [".$_->name."]";
  }
}
{
  my @artists = DBArtists->search_with_min('cds.price',
  	'label.name' => 'eng',
  	{order_by => 'min ASC'}
  );
  is scalar @artists, 3, "WHERE artists.label.name = 'eng'";
  is shift @artists, 2, "ORDER BY MIN(cds.price)";
  is shift @artists, 1, "ORDER BY MIN(cds.price)";
  is shift @artists, 3, "ORDER BY MIN(cds.price)";
}

__END__

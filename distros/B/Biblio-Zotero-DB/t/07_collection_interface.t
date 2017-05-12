use strict;
use warnings;
use Test::Most tests => 8;

use lib "t/lib";
use TestData;

my $db = get_db();

my $library = $db->library;
is( $library->name, 'My Library' );
is( $library->items->count, 11 );

is( $library->trash->name, 'Trash' );
is( $library->trash->items->count, 6 );

is( $library->unfiled->name, 'Unfiled Items' );
is( $library->unfiled->items->count, 7 );

is( $library->collections->count, 3 );

my $collection_count = {
	'Collection with deleted' => 1,
	'Dendritic spines' => 1,
	'Perl' => 2,
};

subtest 'collections items count' => sub {
	for my $collection ($library->collections->all) {
		my $name = $collection->name;
		my $expected_count = $collection_count->{$name};
		is( $collection->items->count, $expected_count, "count for $name" );
	}
};

done_testing;

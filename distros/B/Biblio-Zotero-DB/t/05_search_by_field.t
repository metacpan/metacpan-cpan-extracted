use strict;
use warnings;
use Test::Most tests => 5;

use lib "t/lib";
use TestData;

my $schema = get_db()->schema;

my $items;
ok( $items = $schema->resultset('Item')->search_by_field(
	{
		title => { like => '%perl%' },
		date => { '>' => '2009-00-00 2009' },
	}
), 'got items');

is( $items->count, 1, 'correct number of items');

cmp_deeply(
	$schema->resultset('ItemData')->fields_for_itemid($items->first->itemid),
	{
	    date      =>  "2011-00-12 12 2011",
	    ISBN      =>  9780977920174,
	    publisher =>  "Onyx Neon Press",
	    title     =>  "Modern Perl",
	    url       =>  "http://www.onyxneon.com/books/modern_perl/"
	},
'correct item data');

ok( $items = $schema->resultset('Item')->search_by_field(
	{
		title => { like => '%perl%' },
	}
), 'got items');

isnt( $items->count, 1, 'get more items with fewer constraints');

done_testing;

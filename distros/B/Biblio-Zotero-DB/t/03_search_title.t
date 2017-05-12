use strict;
use warnings;
use Test::Most tests => 5;

use lib "t/lib";
use TestData;

my $schema = get_db()->schema;

my $attachment_itemtypeid = $schema
	->resultset('ItemType')
	->search({ 'typename' => 'attachment' })
	->single->itemtypeid;

my $title_rs;
ok( $title_rs = $schema->resultset('Item')->search(
		{
			'fieldid.fieldname' => 'title',
			'itemtypeid' => { '!=', $attachment_itemtypeid },
			'valueid.value' => { 'like', '%perl%' }
		},
		{
			prefetch => [
					{ 'item_datas' => [ 'fieldid', 'valueid' ] },
				],
		},
	), 'searching for titles contain Perl');

is($title_rs->count, 2, 'got 2 items');

my $titles;
ok( $titles = [
	$title_rs
		->related_resultset('item_datas')
		->related_resultset('valueid')
		->get_column('value')->all
], 'got all titles');

is( scalar @$titles, 2, 'correct number of titles');

cmp_deeply( $titles,
	bag(
		"Higher-order Perl: Transforming programs with programs",
		"Modern Perl",
	),
	'all expected Perl titles are found'
);

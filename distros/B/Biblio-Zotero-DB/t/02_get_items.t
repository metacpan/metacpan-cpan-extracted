use strict;
use warnings;
use Test::Most tests => 7;

use lib "t/lib";
use TestData;

my $schema = get_db()->schema;

my $titles;
my $title_rs;

my $attachment_itemtypeid;


is( $attachment_itemtypeid = $schema
	->resultset('ItemType')
	->search({ 'typename' => 'attachment' })
	->single->itemtypeid, 14, 'got attachment type ID');

ok( $title_rs = $schema->resultset('StoredItem')->search(
		{
			'fieldid.fieldname' => 'title',
			'itemtypeid' => { '!=', $attachment_itemtypeid }
		},
		{
			prefetch => [
					{ 'item_datas' => [ 'fieldid', 'valueid' ] },
				],
		},
	), 'got titles result-set');

ok( $titles = [
	$title_rs
		->related_resultset('item_datas')
		->related_resultset('valueid')
		->get_column('value')->all
], 'got all titles');

is( scalar @$titles, 10, 'correct number of titles');

cmp_deeply( $titles,
	bag(
		"Big Science vs. Little Science: How Scientific Impact Scales with Funding",
		"Cognitive Performance and Heart Rate Variability: The Influence of Fitness Level",
		"Electrical Advantages of Dendritic Spines",
		"Example.org",
		"Higher-order Perl: Transforming programs with programs",
		"Modern Perl",
		"Selective Light-Triggered Release of DNA from Gold Nanorods Switches Blood Clotting On and Off",
		"The Collaborative Image of The City: Mapping the Inequality of Urban Perception",
		"The Power of Kawaii: Viewing Cute Images Promotes a Careful Behavior and Narrows Attentional Focus",
		"Zotero Quick Start Guide",
	),
	'all expected titles are found'
);

my $html_item_rs =  $schema->resultset('StoredItem')
	->items_with_attachments_of_mimetypes('text/html');
ok( $html_item_rs->count >= 1, 'has at least one item with text/html attachment' );
my @html_item_titles = map { $_->fields->{title} } $html_item_rs->all;
cmp_deeply( @html_item_titles, any( 'Example.org'),
	'contains expected item with text/html attachment');

done_testing;


use strict;
use warnings;
use Test::Most tests => 8;

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
			'valueid.value' => 'Modern Perl'
		},
		{
			prefetch => [
					{ 'item_datas' => [ 'fieldid', 'valueid' ] },
				],
		},
	), 'got titles result-set');

is($title_rs->count, 1, 'got 1 item');

my $first_row;
ok( $first_row = $title_rs->first, 'got first row');

my $attachments;

ok($attachments = $first_row->item_attachments_sourceitemids, 'getting attachments');

is($attachments->count, 1, 'has 1 attachment' );

my $book;
ok($book = $attachments->first, 'got book data');

is( $book->mimetype, 'application/pdf', 'book is a PDF');

is( $book->path, "storage:modern_perl_a4.pdf", 'got path');

done_testing;

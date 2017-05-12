use strict;
use warnings;
use Test::Most tests => 11;

use lib "t/lib";
use TestData;

my $db = get_db();

my $attachment_itemtypeid = 14; # ItemType: typename => 'attachment'

my $perl_item_count = $db->schema->resultset('StoredItem')
	->search({ itemtypeid => { '!=' => $attachment_itemtypeid } })
	->search_by_field( { title => { like => '%Perl%' } })->count;
is( $perl_item_count, 2, 'found both Perl items');

my $thresher_shark_count_both = [ map {
		$_->search({ itemtypeid => { '!=' => $attachment_itemtypeid } })
			->search_by_field( { title => { like => '%Thresher%' } })->count
	} ( $db->schema->resultset('Item'), $db->schema->resultset('StoredItem') ) ];
cmp_deeply( $thresher_shark_count_both, [1, 0], 'Thresher shark article is deleted (and thus not stored)');

my $cognitive_count_both = [ map {
		$_->search({ itemtypeid => { '!=' => $attachment_itemtypeid } })
			->search_by_field( { title => { like => '%cognitive%' } })->count
	} ( $db->schema->resultset('Item'), $db->schema->resultset('StoredItem') ) ];
cmp_deeply( $cognitive_count_both, [2, 1], 'Articles with cognitive in the title');



my $original_si_rs = $db->schema->resultset('StoredItem');
is( $original_si_rs->_item_attachment_resultset, "ItemAttachment", 'default item attachment result set');
isa_ok( $original_si_rs, 'Biblio::Zotero::DB::Schema::ResultSet::Item');
my $si_rs_with_another = $original_si_rs->with_item_attachment_resultset('StoredItemAttachment');
isa_ok( $si_rs_with_another, 'Biblio::Zotero::DB::Schema::ResultSet::Item');
is( $si_rs_with_another->_item_attachment_resultset, 'StoredItemAttachment', 'create copy with another' );

is( $original_si_rs->_item_attachment_resultset, "ItemAttachment", 'original still the same');
ok( ! eq_deeply( $original_si_rs, $si_rs_with_another ), 'not the same objects');


my $all_pdfs_anywhere_rs = $db->schema->resultset('Item')->items_with_pdf_attachments;

is( $all_pdfs_anywhere_rs->count, 9, 'all PDF anywhere (stored and deleted)' );

sub get_titles {
	my $rs = shift;
	[ map { $_->fields->{title}  } $rs->all];
}

my $storeditems_with_storeditemattachments_pdf_rs = $db->schema
	->resultset('StoredItem')
	->with_item_attachment_resultset('StoredItemAttachment')
	->items_with_pdf_attachments;
cmp_deeply( get_titles($storeditems_with_storeditemattachments_pdf_rs), bag(
	"Higher-order Perl: Transforming programs with programs",
	"Modern Perl",
	"Electrical Advantages of Dendritic Spines",
	"Big Science vs. Little Science: How Scientific Impact Scales with Funding",
	"Patrick-Wyatt-Writing-reliable-online-game-services.pdf",
	"The Power of Kawaii: Viewing Cute Images Promotes a Careful Behavior and Narrows Attentional Focus"),
	'all stored items that have PDFs that are also stored');

done_testing;

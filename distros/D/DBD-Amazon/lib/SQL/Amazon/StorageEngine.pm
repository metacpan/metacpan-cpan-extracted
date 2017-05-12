#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::StorageEngine;
use SQL::Amazon::Tables::SysSchema;
use strict;
use constant AMZN_STORE_TABLES => 0;
use constant AMZN_STORE_ERRSTR => 1;
our %amzn_table_classes = (
'ACCESSORIES', 'SQL::Amazon::Tables::Accessories',
'APPAREL', 'SQL::Amazon::Tables::Apparel',
'BABY', 'SQL::Amazon::Tables::Baby',
'BEAUTY', 'SQL::Amazon::Tables::Beauty',
'BLENDED', 'SQL::Amazon::Tables::Blended',
'BOOKS', 'SQL::Amazon::Tables::Books',
'BROWSENODES', 'SQL::Amazon::Tables::BrowseNodes',
'CAMERAPHOTO', 'SQL::Amazon::Tables::Photo',
'CLASSICALMUSIC', 'SQL::Amazon::Tables::ClassicalMusic',
'CUSTOMERREVIEWS', 'SQL::Amazon::Tables::CustomerReviews',
'CUSTOMERS', 'SQL::Amazon::Tables::Customers',
'DIGITALMUSIC', 'SQL::Amazon::Tables::DigitalMusic',
'DVDS', 'SQL::Amazon::Tables::DVDs',
'EDITORIALREVIEWS', 'SQL::Amazon::Tables::EditorialReviews',
'ELECTRONICS', 'SQL::Amazon::Tables::Electronics',
'GOURMETFOOD', 'SQL::Amazon::Tables::GourmetFood',
'HARDWARE', 'SQL::Amazon::Tables::Hardware',
'HEALTHPERSONALCARE', 'SQL::Amazon::Tables::HealthPersonalCare',
'HOMEGARDEN', 'SQL::Amazon::Tables::HomeGarden',
'ITEMS', 'SQL::Amazon::Tables::Items',
'ITEMATTRIBUTES', 'SQL::Amazon::Tables::ItemAttributes',
'ITEMFEATURES', 'SQL::Amazon::Tables::ItemFeatures',
'JEWELRY', 'SQL::Amazon::Tables::Jewelry',
'KITCHEN', 'SQL::Amazon::Tables::Kitchen',
'LISTMANIALISTS', 'SQL::Amazon::Tables::ListManiaLists',
'MAGAZINES', 'SQL::Amazon::Tables::Magazines',
'MERCHANTS', 'SQL::Amazon::Tables::Merchants',
'MISCELLANEOUS', 'SQL::Amazon::Tables::Miscellaneous',
'MUSIC', 'SQL::Amazon::Tables::Music',
'MUSICALINSTRUMENTS', 'SQL::Amazon::Tables::MusicalInstruments',
'MUSICTRACKS', 'SQL::Amazon::Tables::MusicTracks',
'OFFERS', 'SQL::Amazon::Tables::Offers',
'OFFERLISTINGS', 'SQL::Amazon::Tables::OfferListings',
'OFFICEPRODUCTS', 'SQL::Amazon::Tables::OfficeProducts',
'OUTDOORLIVING', 'SQL::Amazon::Tables::OutdoorLiving',
'PCHARDWARE', 'SQL::Amazon::Tables::PCHardware',
'RESTAURANTS', 'SQL::Amazon::Tables::Restaurants',
'SAVEDITEMS', 'SQL::Amazon::Tables::SavedItems',
'SYSSCHEMA', 'SQL::Amazon::Tables::SysSchema',
'SELLERS', 'SQL::Amazon::Tables::Sellers',
'SELLERFEEDBACK', 'SQL::Amazon::Tables::SellerFeedback',
'SELLERLISTINGS', 'SQL::Amazon::Tables::SellerListings',
'SIMILARITEMS', 'SQL::Amazon::Tables::SimilarItems',
'SIMILARPRODUCTS', 'SQL::Amazon::Tables::SimilarProducts',
'SOFTWARE', 'SQL::Amazon::Tables::Software',
'SPORTINGGOODS', 'SQL::Amazon::Tables::SportingGoods',
'TRACKS', 'SQL::Amazon::Tables::Tracks',
'TRANSACTIONS', 'SQL::Amazon::Tables::Transactions',
'TRANSACTIONITEMS', 'SQL::Amazon::Tables::TransactionItems',
'TOYS', 'SQL::Amazon::Tables::Toys',
'VARIATIONS', 'SQL::Amazon::Tables::Variations',
'VHS', 'SQL::Amazon::Tables::VHS',
'VIDEO', 'SQL::Amazon::Tables::Video',
'VIDEOLANGUAGES', 'SQL::Amazon::Tables::VideoLanguages',
'VIDEOGAMES', 'SQL::Amazon::Tables::VideoGames',
'WIRELESS', 'SQL::Amazon::Tables::Wireless',
'WIRELESSACCESSORIES', 'SQL::Amazon::Tables::WirelessAccessories',
);
our %amzn_table_names = (
'ACCESSORIES', [ 'Accessories', 'Item' ],
'APPAREL', [ 'Apparel', 'Item' ],
'BABY', [ 'Baby', 'Item' ],
'BEAUTY', [ 'Beauty', 'Item' ],
'BLENDED', [ 'Blended', 'Item' ],
'BOOKS', [ 'Books', 'Item' ],
'BROWSENODES', [ 'BrowseNodes', 'BrowseNode' ],
'CAMERAPHOTO', [ 'Photo', 'Item' ],
'CART', [ 'Cart', 'Cart' ],
'CLASSICALMUSIC', [ 'ClassicalMusic', 'Item' ],
'CUSTOMERREVIEWS', [ 'CustomerReviews', 'CustomerContent' ],
'CUSTOMERS', [ 'Customers', 'CustomerContent' ],
'DIGITALMUSIC', [ 'DigitalMusic', 'Item' ],
'DVDS', [ 'DVDs', 'Item' ],
'EDITORIALREVIEWS', [ 'EditorialReviews', undef ],
'ELECTRONICS', [ 'Electronics', 'Item' ],
'GOURMETFOOD', [ 'GourmetFood', 'Item' ],
'HARDWARE', [ 'Hardware', 'Item' ],
'HEALTHPERSONALCARE', [ 'HealthPersonalCare', 'Item' ],
'HOMEGARDEN', [ 'HomeGarden', 'Item' ],
'ITEMS', [ 'Items', 'Item' ],
'ITEMATTRIBUTES', [ 'ItemAttributes', undef ],
'ITEMFEATURES', [ 'ItemFeatures', undef ],
'JEWELRY', [ 'Jewelry', 'Item' ],
'KITCHEN', [ 'Kitchen', 'Item' ],
'LISTMANIALISTS', [ 'ListManiaLists', 'Lists' ],
'MAGAZINES', [ 'Magazines', 'Item' ],
'MERCHANTS', [ 'Merchants', 'Merchants', 'Sellers' ],
'MISCELLANEOUS', [ 'Miscellaneous', 'Item' ],
'MUSIC', [ 'Music', 'Item' ],
'MUSICALINSTRUMENTS', [ 'MusicalInstruments', 'Item' ],
'MUSICTRACKS', [ 'MusicTracks', 'Item' ],
'OFFERS', [ 'Offers', undef ],
'OFFERLISTINGS', [ 'OfferListings', undef ],
'OFFICEPRODUCTS', [ 'OfficeProducts', 'Item' ],
'OUTDOORLIVING', [ 'OutdoorLiving', 'Item' ],
'PURCHASES', [ 'Purchases', undef ],
'PCHARDWARE', [ 'PCHardware', 'Item' ],
'RESTAURANTS', [ 'Restaurants', 'Item' ],
'SAVEDITEMS', [ 'SavedItems', 'Cart' ],
'SELLERS', [ 'Sellers', 'Sellers' ],
'SELLERFEEDBACK', [ 'SellerFeedback', 'Sellers' ],
'SELLERLISTINGS', [ 'SellerListings', 'Sellers' ],
'SIMILARITEMS', [ 'SimilarItems', 'Similar' ],
'SIMILARPRODUCTS', [ 'SimilarProducts', 'Similar' ],
'SOFTWARE', [ 'Software', 'Item' ],
'SPORTINGGOODS', [ 'SportingGoods', 'Item' ],
'TRACKS', [ 'Tracks', 'Item' ],
'TRANSACTIONS', [ 'Transactions', 'Transactions' ],
'TRANSACTIONITEMS', [ 'TransactionItems', 'Transactions' ],
'TOYS', [ 'Toys', 'Item' ],
'VARIATIONS', [ 'Variations', 'Item' ],
'VHS', [ 'VHS', 'Item' ],
'VIDEO', [ 'Video', 'Item' ],
'VIDEOLANGUAGES', [ 'VideoLanguages', 'Item' ],
'VIDEOGAMES', [ 'VideoGames', 'Item' ],
'WIRELESS', [ 'Wireless', 'Item' ],
'WIRELESSACCESSORIES', [ 'WirelessAccessories', 'Item' ],
);

sub new {
	my $class = shift;
	my $obj = [ {} ];
	$obj->[AMZN_STORE_TABLES]{SYSSCHEMA} =
		SQL::Amazon::Tables::SysSchema->new;

	bless $obj, $class;
	return $obj;
}
sub has_table {
	my $table = shift;
	$table = $1 if ($table=~/^CACHED(\w+)$/i);

	return wantarray ? @{$amzn_table_names{uc $table}} : 
		$amzn_table_names{uc $table}[0];
}

sub get_table {
	my ($obj, $table) = @_;
	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$obj->[AMZN_STORE_ERRSTR] = 'Unknown table $table.',
	return undef
		unless $amzn_table_classes{uc $table};
	$table = uc $table;
	$obj->[AMZN_STORE_ERRSTR] = undef;
	unless ($obj->[AMZN_STORE_TABLES]{$table}) {
		eval "require $amzn_table_classes{$table};";
		$obj->[AMZN_STORE_ERRSTR] = $@,
		return undef
			if $@;
		my $class = $amzn_table_classes{$table};
		$obj->[AMZN_STORE_TABLES]{$table} = ${class}->new();
	}
	return $obj->[AMZN_STORE_TABLES]{$table};
}
sub debug {
	my ($obj, $debug, @tables) = @_;
	
	unless (scalar @tables) {
		$_->debug($debug)
			foreach (values %{$obj->[AMZN_STORE_TABLES]});
		return $obj;
	}

	foreach (@tables) {
		$obj->[AMZN_STORE_TABLES]{$_}->debug($debug)
			if $obj->[AMZN_STORE_TABLES]{uc $_};
	}
	return $obj;
}
sub close {
	my $obj = shift;
	delete $obj->[AMZN_STORE_TABLES]{$_}
		foreach (keys %{$obj->[AMZN_STORE_TABLES]});
	return $obj;
}

sub DESTROY {
	shift->close;
	1;
}
sub cache_item {
	my ($obj, $table, $row) = @_;

	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$table = uc $table;
	my $table_obj = $obj->get_table($table);
	return undef 
		unless $table_obj;

	$obj->[AMZN_STORE_ERRSTR] = $table_obj->errstr,
	return undef 
		unless $table_obj->insert($row);
	return $obj;
}
sub spoil_cache_item {
	my ($obj, $id, $table) = @_;
	
	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$obj->[AMZN_STORE_TABLES]{$table}->spoil($id)
		if $obj->[AMZN_STORE_TABLES]{$table};
	
	return $obj;
}

sub spoil_cache_table {
	my ($obj, $table) = @_;
	
	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$obj->[AMZN_STORE_TABLES]{$table}->spoil_all()
		if $obj->[AMZN_STORE_TABLES]{$table};
	
	return $obj;
}

sub spoil_cache_all {
	my $obj = shift;
	
	$obj->spoil_cache_table($_)
		foreach (keys %{$obj->[AMZN_STORE_TABLES]});

	return $obj;
}
sub send_requests {
	my ($obj, $requests) = @_;

	my $start = time();
	my %reqids = ();
	my $warnmsg;
	my $reqno = 1;
	foreach (@$requests) {
		$_->{_reqno} = $reqno++;
		return ($_->errstr, undef, undef)
			unless $_->send_request($obj, \%reqids);
		$warnmsg = $_->warnstr unless $warnmsg;
	}
	return ($warnmsg, \%reqids, time() - $start);
}
sub get_result_set {
	my ($obj, $table, $reqids) = @_;
	$reqids = undef,
	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$table = uc $table;
	return undef 
		unless $obj->[AMZN_STORE_TABLES]{$table};
	return SQL::Amazon::Spool->new($obj->[AMZN_STORE_TABLES]{$table}, $reqids);
}
sub fetch_row {
	my ($obj, $table, $id, $timeout) = @_;

	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	return $obj->[AMZN_STORE_TABLES]{$table} ?
		$obj->[AMZN_STORE_TABLES]{$table}->fetch($id, $timeout) :
		"Unknown table $table.";
}

sub is_readonly { 
	my ($obj, $table) = @_;

	$table = $1 
		if ($table=~/^CACHED(\w+)$/i);

	$table = uc $table;
	return $obj->[AMZN_STORE_TABLES]{$table} ? 
		$obj->[AMZN_STORE_TABLES]{$table}->is_readonly : 1;
}

sub errstr { return shift->[AMZN_STORE_ERRSTR]; }

1;

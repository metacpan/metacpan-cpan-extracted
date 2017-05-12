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
=pod

=head4 Books (view, readonly)

Item attribute view specific to Books

=over 4

=item ASIN

=item Author

=item Creator

=item Title

=item ProductGroup

=item ListPriceAmt

=item ListPriceCurrency

=item ListPriceFormatted

=item EAN

=item Binding

=item DeweyDecimalNumber

=item EAN

=item ISBN

=item Length

=item Width

=item Height

=item NumberOfItems

=item NumberOfPages

=item PublicationDate

=item Publisher

=item ReadingLevel

=item Weight

=back

=cut

package SQL::Amazon::Tables::Books;

use DBI qw(:sql_types);

use base qw(SQL::Amazon::Tables::Table);

use strict;

my %sort_params = (
'relevancerank', 1, 
'salesrank', 1, 	
'reviewrank', 1, 	
'pricerank', 1, 	
'inverse-pricerank', 1,
'daterank', 1, 		
'titlerank', 1, 	
'-titlerank', 1, 	
);

my %browse_nodes =  (
'Arts & Photography', 1,
'Biographies & Memoirs', 2,
'Business & Investing', 3,
'Children\'s Books', 4,
'Comics & Graphic Novels', 4366,
'Computers & Internet', 5,
'Cooking, Food & Wine', 6,
'Engineering', 13643,
'Entertainment', 86,
'Gay & Lesbian', 301889,
'Health, Mind & Body', 10,
'History', 9,
'Home & Garden', 48,
'Horror', 49,
'Law', 10777,
'Literature & Fiction', 17,
'Medicine', 13996,
'Mystery & Thrillers', 18,
'Nonfiction', 53,
'Outdoors & Nature', 290060,
'Parenting & Families', 20,
'Professional & Technical', 173507,
'Reference', 21,
'Religion & Spirituality', 22,
'Romance', 23,
'Science', 75,
'Science Fiction & Fantasy', 25,
'Sports', 26,
'Teens', 28,
'Travel', 27,
);

our %metadata = (
	'NAME', [
	qw/ASIN Authors Creator Title ProductGroup ListPriceAmt ListPriceCurrency
	ListPriceFormatted 
	EAN Binding DeweyDecimalNumber ISBN NumberOfItems
	NumberOfPages PublicationDate Publisher ReadingLevel DetailPageURL SalesRank
	SmallImageURL SmallImageHeight SmallImageWidth MediumImageURL
	MediumImageHeight MediumImageWidth LargeImageURL
	LargeImageHeight LargeImageWidth OfferCount TotalNew
	LowestNewPriceAmt LowestNewPriceCurrency
	LowestNewPriceFormatted TotalUsed LowestUsedPriceAmt
	LowestUsedPriceCurrency LowestUsedPriceFormatted
	TotalCollectible 
	LowestCollectiblePriceAmt
	LowestCollectiblePriceCurrency 
	LowestCollectiblePriceFormatted

	TotalRefurbished 
	LowestRefurbishedPriceAmt
	LowestRefurbishedPriceCurrency 
	LowestRefurbishedPriceFormatted

	VariationCount VariationLowPriceAmt VariationLowPriceCurrency 
	VariationLowPriceFormatted VariationHighPriceAmt
	VariationHighPriceCurrency VariationHighPriceFormatted
	VariationLowSalePriceAmt VariationLowSalePriceCurrency 
	VariationLowSalePriceFormatted VariationHighSalePriceAmt
	VariationHighSalePriceCurrency VariationHighSalePriceFormatted
	SingleMerchantID AverageRating TotalCustomerReviews
	TotalOffers/
	],
	'TYPE', [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_DATE,	
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_INTEGER,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,

	SQL_INTEGER,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,

	SQL_INTEGER,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,

	SQL_INTEGER,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_INTEGER,
	SQL_INTEGER,
	],
	'PRECISION', [
	32,
	256,# Authors 
	256,# Creator 
	256,# Title 
	256,# ProductGroup 
	15,
	10,
	32,
	32,
	32,
	32,
	32,
	10,
	10,
	10,
	256,# Publisher 
	32,
	256,# DetailPageURL 
	10,
	256,# SmallImageURL 
	10,
	10,
	256,# MediumImageURL
	10,
	10,
	256,# LargeImageURL
	10,
	10,
	10,
	10,
	15,
	10,
	32,
	10,
	15,
	10,
	32,

	10,
	15,
	10,
	32,

	10,
	15,
	10,
	32,

	10,
	15,
	10,
	32,
	15,
	10,
	32,
	15,
	10,
	32,
	15,
	10,
	32,
	32,
	15,
	10,
	10,
	],
	'SCALE', [
	undef,
	undef,
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,

	undef,
	2,	
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,
	2,	
	undef,
	undef,
	2,	
	undef,
	undef,
	2,	
	undef,
	undef,
	undef,
	2,	
	undef,
	undef,
	],
	'NULLABLE', [
	undef,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	return $obj;
}
sub insert {
	my ($obj, $item, $asin, $reqid) = @_;
	my $names = $obj->{NAME};
	my $types = $obj->{TYPE};
	my @row = ();
	my $colnums = $obj->{col_nums};
	$row[$colnums->{ASIN}] = $item->{ASIN};
	$row[$colnums->{DetailPageURL}] = $item->{DetailPageURL};
	$row[$colnums->{SalesRank}] = $item->{SalesRank};
	foreach ('SmallImage', 'MediumImage', 'LargeImage') {
		$row[$colnums->{$_ . 'URL'}] = $item->{$_}{URL},
		$row[$colnums->{$_ . 'Height'}] = $item->{$_}{Height},
		$row[$colnums->{$_ . 'Width'}] = $item->{$_}{Width}
			if $item->{$_};
	}

	my $attrs =	$item->{OfferSummary};
	if ($attrs) {
		$row[$colnums->{TotalCollectible}] = $attrs->{TotalCollectible};
		$row[$colnums->{TotalNew}] = $attrs->{TotalNew};
		$row[$colnums->{TotalUsed}] = $attrs->{TotalUsed};
		$row[$colnums->{TotalRefurbished}] = $attrs->{TotalRefurbished};
		foreach ('LowestNewPrice', 'LowestUsedPrice', 
			'LowestCollectiblePrice', 'LowestRefurbishedPrice') {

			$row[$colnums->{$_ . 'Amt'}] = $obj->format_money($attrs->{$_}{Amount}),
			$row[$colnums->{$_ . 'Currency'}] = $attrs->{$_}{CurrencyCode},
			$row[$colnums->{$_ . 'Formatted'}] = $attrs->{$_}{FormattedPrice}
				if $attrs->{$_};
		}
	}
	$attrs = $item->{ItemAttributes};
	if ($attrs) {
		$row[$colnums->{Authors}] = ref $attrs->{Author} ? 
			join('; ', @{$attrs->{Author}}) : 
			$attrs->{Author}
			if $attrs->{Author};
		$row[$colnums->{Binding}] = $attrs->{Binding};
		$row[$colnums->{EAN}] = $attrs->{EAN};
		$row[$colnums->{ISBN}] = $attrs->{ISBN};
		$row[$colnums->{NumberOfItems}] = $attrs->{NumberOfItems} || 1;
		$row[$colnums->{NumberOfPages}] = $attrs->{NumberOfPages};
		$row[$colnums->{PublicationDate}] = 
			$obj->format_date($attrs->{PublicationDate})
			if $attrs->{PublicationDate};
		$row[$colnums->{Publisher}] = $attrs->{Publisher};
		$row[$colnums->{Title}] = $attrs->{Title};
		$row[$colnums->{ProductGroup}] = $attrs->{ProductGroup};
		if ($attrs->{ListPrice}) {
			$row[$colnums->{ListPriceAmt}] = 
				$obj->format_money($attrs->{ListPrice}{Amount})
				if $attrs->{ListPrice}{Amount};
			$row[$colnums->{ListPriceCurrency}] = 
				$attrs->{ListPrice}{CurrencyCode};
			$row[$colnums->{ListPriceFormatted}] = 
				$attrs->{ListPrice}{FormattedPrice};
		}
	}

	$attrs = $item->{Offers};
	$row[$colnums->{TotalOffers}] = $attrs->{TotalOffers}
		if $attrs;
	$attrs = $item->{CustomerReviews};
	$row[$colnums->{TotalCustomerReviews}] = $attrs->{TotalReviews},
	$row[$colnums->{AverageRating}] = $attrs->{AverageRating}
		if $attrs;
	
	return $obj->SUPER::save_row(\@row, $item, $reqid);
}

1;

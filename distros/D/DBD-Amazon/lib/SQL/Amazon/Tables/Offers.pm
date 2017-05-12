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

=head4 Offers (table, readonly)

Product offer information including non-Amazon sources

=over 4

=item ASIN 		- Amazon ID; primary key

=item MerchantID	- ID of Offer merchant/seller

=item Condition	- new/used/refurb/etc.

=item SubCondition - detailed condition info

=item ConditionNote - more detail

=back

=cut

package SQL::Amazon::Tables::Offers;

use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);
use strict;

our %metadata = (
	NAME => [
	qw/ASIN
	MerchantId
	GlancePage
	OfferListingId
	PriceAmt
	PriceCurrency
	PriceFormatted
	SalePriceAmt
	SalePriceCurrency
	SalePriceFormatted
	Availability
	ISPUStoreAddress
	ISPUStoreHours
	Condition
	SubCondition
	ConditionNote/
	],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DECIMAL,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	],
	PRECISION => [
	32,
	32,
	256,
	32,
	15,
	10,
	32,
	15,
	10,
	32,
	256,
	256,
	256,
	32,
	256,
	1024,
	],
	SCALE => [
	undef,
	undef,
	undef,
	undef,
	2,
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
	],
	NULLABLE => [
	undef,
	undef,
	1,
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
	]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	$obj->{_key_cols} = [ 0, 1, 3 ];
	return $obj;
}

sub insert {
	my ($obj, $offer, $asin, $reqid) = @_;
	my $names = $obj->{NAME};
	my $types = $obj->{TYPE};
	my @row = ();
	my $colnums = $obj->{col_nums};
	$row[$colnums->{ASIN}] = $asin;
	$row[$colnums->{MerchantId}] = 
		$offer->{Merchant}{MerchantId},
	$row[$colnums->{GlancePage}] = 
		$offer->{Merchant}{GlancePage}
		if $offer->{Merchant};

	$row[$colnums->{Condition}] = 
		$offer->{OfferAttributes}{Condition}
		if $offer->{OfferAttributes};

	if ($offer->{OfferListing}) {
		$offer = $offer->{OfferListing};
		$row[$colnums->{Availability}] = 
			$offer->{Availability};
		$row[$colnums->{OfferListingId}] = 
			$offer->{OfferListingId};

		$row[$colnums->{PriceAmt}] = 
			$obj->format_money($offer->{Price}{Amount}),
		$row[$colnums->{PriceCurrency}] = 
			$offer->{Price}{CurrencyCode},
		$row[$colnums->{PriceFormatted}] = 
			$offer->{Price}{FormattedPrice}
			if $offer->{Price};
	}
	
	return $obj->SUPER::save_row(\@row, $offer, $reqid);
}

1;


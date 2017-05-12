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

=head4 Merchants (table, readonly)

=over 4

=item MerchantID 	- primary key (US only, SellerID in other locales)

=item Name		- Merchant/Seller name

=item Nickname	- Merchant/Seller nickname

=item GlancePage 	- URL of page with seller info

=item About		- brief info regarding seller

=item MoreAbout	- extended info regarding seller

=item Location	- geographic info (variable format)

=item AvgFeedback	- Average feed back rating

=item TotalFeedback - number of customers who provided feedback

=back

=cut

package SQL::Amazon::Tables::Merchants;

use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);
use strict;

our %metadata = (
	NAME => [ 
	qw/MerchantID Name Nickname GlancePage About MoreAbout
	Location AvgFeedback TotalFeedback/
	],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_FLOAT,
	SQL_INTEGER,
	],
	PRECISION => [
	32,
	256,
	256,
	256,
	1024,
	1024,
	256,
	24,
	10,
	],
	SCALE => [
	undef,
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
	$obj->{_key_cols} = [ 0 ];
	return $obj;
}

1;


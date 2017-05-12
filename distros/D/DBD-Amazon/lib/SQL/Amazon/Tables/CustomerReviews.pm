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

=head4 CustomerReviews (table, readonly)

Product reviews provided by customers

=over 4

=item ASIN

=item Content

=item ReviewDate

=item HelpfulVotes

=item Rating

=item Summary

=item TotalVotes

=back

=cut

package SQL::Amazon::Tables::CustomerReviews;

use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);

use strict;

our %metadata = (
	NAME => [ 
	qw/ASIN 
	CustomerId
	ReviewDate 
	Rating 
	Content 
	Summary 
	HelpfulVotes 
	TotalVotes/
	],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_DATE, 	
	SQL_FLOAT, 	
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_INTEGER,
	SQL_INTEGER,
	],
	PRECISION => [
	32,
	32,
	10,
	24,
	1024,
	256,
	10,
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
	],
	NULLABLE => [
	undef,
	undef,
	1, 	
	1, 	
	undef,
	1,
	1,
	1,
	]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	$obj->{_key_cols} = [ 0, 1];
	return $obj;
}

1;


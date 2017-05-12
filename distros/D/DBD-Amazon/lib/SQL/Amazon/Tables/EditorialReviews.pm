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

=head4 EditorialReviews (table, readonly)

Product reviews by professional published sources, keyed by ASIN

=over 4

=item ASIN

=item EditorialReview

=back

=cut

package SQL::Amazon::Tables::EditorialReviews;

use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);

use strict;

our %metadata = (
	NAME => [ qw/ASIN EditorialReview Source/ ],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR
	],
	PRECISION => [
	32,
	1024,
	256,
	],
	SCALE => [undef, undef, undef],
	NULLABLE => [undef, undef, undef]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	return $obj;
}

1;


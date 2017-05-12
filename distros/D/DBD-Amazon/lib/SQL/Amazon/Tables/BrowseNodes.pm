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

=head4 BrowseNodes (table, readonly)

Product category BrowseNodes, keyed by ASIN

=over 4

=back

=cut

package SQL::Amazon::Tables::BrowseNodes;

use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);

use strict;

our %metadata = (
	NAME => [ qw/ASIN BrowseNodeID Name/],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR
	],
	PRECISION => [
	32,
	32,
	256
	],
	SCALE => [ undef, undef, undef ],
	NULLABLE => [ undef, undef, undef ]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	$obj->{_key_cols} = [ 0, 1 ];
	return $obj;
}

1;


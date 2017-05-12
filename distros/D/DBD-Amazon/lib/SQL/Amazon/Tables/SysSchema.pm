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
package SQL::Amazon::Tables::SysSchema;
use DBI qw(:sql_types);
use base qw(SQL::Amazon::Tables::Table);
use strict;
my %amzn_catalog = (
'BOOKS', [ undef, undef, 'BOOKS', 'VIEW', 'Base view for Book products' ],
'BROWSENODES', [ undef, undef, 'BROWSENODES', 'VIEW', 'Lists BrowseNode names and identifiers associated with a given ASIN' ],
'CUSTOMERREVIEWS', [ undef, undef, 'CUSTOMERREVIEWS', 'VIEW', 'Lists customer reviews for a given ASIN' ],
'EDITORIALREVIEWS', [ undef, undef, 'EDITORIALREVIEWS', 'VIEW', 'Lists editorial reviews for a given ASIN' ],
'LISTMANIALISTS', [ undef, undef, 'LISTMANIALISTS', 'VIEW', 'Lists ListManiaLists which reference the given ASIN' ],
'MERCHANTS', [ undef, undef, 'MERCHANTS', 'VIEW', 'Lists publicly available information for merchants' ],
'OFFERS', [ undef, undef, 'OFFERS', 'VIEW', 'Lists available offer details for a specified ASIN' ],
'SYSSCHEMA', [ undef, undef, 'SYSSCHEMA', 'SYSTEM TABLE', 'The schema catalog table for DBD::Amazon' ],
'SIMILARPRODUCTS', [ undef, undef, 'SIMILARPRODUCTS', 'VIEW', 'Lists Similar products for a given ASIN' ],
);

my @amzn_columns = qw(
TABLE_CAT
TABLE_SCHEM
TABLE_NAME
TABLE_TYPE
REMARKS
);

our %metadata = (
	NAME => [ 
	qw/TABLE_CAT
	TABLE_SCHEM
	TABLE_NAME
	TABLE_TYPE
	REMARKS/
	],
	TYPE => [
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	SQL_VARCHAR,
	],
	PRECISION => [
	256,
	256,
	256,
	256,
	256,
	],
	SCALE => [],
	NULLABLE => [
	1,
	1,
	undef,
	undef,
	1
	]
);

sub new {
	my $class = shift;
	my $obj = $class->SUPER::new(\%metadata);
	$obj->{_local} = 1;
	$obj->{_cache_only} = 1;
	$obj->{_key_cols} = [ 0, 1, 2 ];
	$obj->save_row($_, undef, 1)
		foreach (values %amzn_catalog);
	return $obj;
}

1;


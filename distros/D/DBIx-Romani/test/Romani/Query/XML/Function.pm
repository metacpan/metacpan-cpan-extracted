#!/usr/bin/perl -w

package Local::Romani::Query::XML::Function;
use base qw(Test::Class);

use DBIx::Romani::Query::XML::Function;
use DBIx::Romani::Driver::sqlite;
use XML::GDOME;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub parse
{
	my $xml = shift;
	
	my $doc  = XML::GDOME->createDocFromString( $xml );
	my $func = DBIx::Romani::Query::XML::Function::create_function_from_node( $doc->getDocumentElement() );

	return $func;
}

sub xmlFunction1 : Test(1)
{
	my $xml = << "EOF";
<func:count distinct="true"
xmlns     ="http://www.carspot.com/query"
xmlns:func="http://www.carspot.com/query-function">
	<column>column_name</column>
</func:count>
EOF

	my $func = parse( $xml );
	my $sql  = generate_sql( $func );
	is ( $sql, 'COUNT(DISTINCT column_name)');
}

1;


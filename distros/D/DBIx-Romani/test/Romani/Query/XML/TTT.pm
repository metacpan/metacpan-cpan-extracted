#!/usr/bin/perl -w

package Local::Romani::Query::XML::TTT;
use base qw(Test::Class);

use DBIx::Romani::Query::XML::TTT;
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
	
	my $doc = XML::GDOME->createDocFromString( $xml );
	my $ttt = DBIx::Romani::Query::XML::TTT::create_ttt_from_node( $doc->getDocumentElement() );

	return $ttt;
}

sub xmlTTT1 : Test(1)
{
	my $xml = << "EOF";
<ttt op="and"
xmlns="http://www.carspot.com/query">
	<ttt op="=">
		<column>column1</column>
		<literal>ABC</literal>
	</ttt>
	<ttt op="=">
		<column>column2</column>
		<literal>123</literal>
	</ttt>
</ttt>
EOF

	my $ttt  = parse( $xml );
	my $s = generate_sql( $ttt );
	is( $s, "((column1 = 'ABC') and (column2 = '123'))" );
}

sub xmlTTT2 : Test(1)
{
	my $xml = << "EOF";
<ttt op="and"
xmlns="http://www.carspot.com/query"
xmlns:op="http://www.carspot.com/query-operator">
	<ttt op="=">
		<column>column1</column>
		<literal>ABC</literal>
	</ttt>
	<op:equal>
		<column>column2</column>
		<literal>123</literal>
	</op:equal>
</ttt>
EOF

	my $ttt  = parse( $xml );
	my $s = generate_sql( $ttt );
	is( $s, "((column1 = 'ABC') and column2 = '123')" );
}

sub xmlTTT3 : Test(1)
{
	my $xml = << "EOF";
<ttt
xmlns="http://www.carspot.com/query"
xmlns:op="http://www.carspot.com/query-operator">
	<ttt keyword="ONE"/>
	<ttt keyword="TWO"/>
</ttt>
EOF

	my $ttt = parse( $xml );
	my $s = generate_sql( $ttt );
	is( $s, "ONE TWO" );
}

sub xmlTTT4 : Test(1)
{
	my $xml = << "EOF";
<ttt func="COUNT"
xmlns="http://www.carspot.com/query"
xmlns:op="http://www.carspot.com/query-operator">
	<ttt>
		<ttt keyword="DISTINCT"/>
		<column>column1</column>
	</ttt>
</ttt>
EOF

	my $ttt = parse( $xml );
	my $s = generate_sql( $ttt );
	is( $s, "COUNT(DISTINCT column1)" );
}

1;


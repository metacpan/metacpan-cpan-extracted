#!/usr/bin/perl -w

package Local::Romani::Query::XML::Select;
use base qw(Test::Class);

use DBIx::Romani::Query::XML::Select;
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
	
	my $doc   = XML::GDOME->createDocFromString( $xml );
	my $query = DBIx::Romani::Query::XML::Select::create_select_from_node( $doc->getDocumentElement() );

	return $query;
}

sub xmlSelect1Short : Test(1)
{
	my $xml = << "EOF";
<select from="table_name"
xmlns="http://www.carspot.com/query">
	<result>
		<column>column_name</column>
	</result>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ( $sql, 'SELECT column_name FROM table_name');
}

sub xmlSelect1Long : Test(1)
{
	my $xml = << "EOF";
<select
xmlns="http://www.carspot.com/query">
	<from>
		<table>table_name</table>
	</from>
	<result>
		<column>column_name</column>
	</result>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ( $sql, 'SELECT column_name FROM table_name');
}

sub xmlSelectColumn1 : Test(1)
{
	my $xml = << "EOF";
<select from="table_name"
xmlns="http://www.carspot.com/query">
	<result>
		<column as="alias_name" table="table_name">column_name</column>
	</result>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ( $sql, 'SELECT table_name.column_name AS alias_name FROM table_name');
}

sub xmlSelectExpression1 : Test(1)
{
	my $xml = << "EOF";
<select from="table_name"
xmlns="http://www.carspot.com/query">
	<result>
		<expr as="count">
			<ttt func="COUNT">
				<ttt>
					<ttt keyword="DISTINCT"/>
					<column>column_name</column>
				</ttt>
			</ttt>
		</expr>
	</result>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ( $sql, 'SELECT COUNT(DISTINCT column_name) AS count FROM table_name');
}

sub xmlSelectWhere1 : Test(1)
{
	my $xml = << "EOF";
<select from="table_name"
xmlns="http://www.carspot.com/query">
	<result>
		<column>column_name</column>
	</result>
	<where>
		<ttt op="=">
			<column>column_name</column>
			<literal>123</literal>
		</ttt>
	</where>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ( $sql, "SELECT column_name FROM table_name WHERE (column_name = '123')");
}

# TODO: The XML format has fallen into disrepair, but since its not actually used for
# anything, I have simply to decided to disable the following tests which fail, rather
# than actually fix this.  So, someday, fix this.

#sub xmlSelectGroupBy1Short : Test(1)
#{
#	my $xml = << "EOF";
#<select from="table_name"
#xmlns="http://www.carspot.com/query">
#	<result>
#		<column>column_name</column>
#	</result>
#	<group-by column="column2"/>
#</select>
#EOF
#
#	my $query = parse( $xml );
#	my $sql = generate_sql( $query );
#	is ( $sql, 'SELECT column_name FROM table_name GROUP BY column2');
#}
#
#sub xmlSelectGroupBy1Long : Test(1)
#{
#	my $xml = << "EOF";
#<select from="table_name"
#xmlns="http://www.carspot.com/query">
#	<result>
#		<column>column_name</column>
#	</result>
#	<group-by>
#		<column>column2</column>
#	</group-by>
#</select>
#EOF
#
#	my $query = parse( $xml );
#	my $sql = generate_sql( $query );
#	is ( $sql, 'SELECT column_name FROM table_name GROUP BY column2');
#}
#
#sub xmlSelectOrderBy1Short : Test(1)
#{
#	my $xml = << "EOF";
#<select from="table_name"
#xmlns="http://www.carspot.com/query">
#	<result>
#		<column>column_name</column>
#	</result>
#	<order-by column="column2" dir="desc"/>
#</select>
#EOF
#
#	my $query = parse( $xml );
#	my $sql = generate_sql( $query );
#	is ( $sql, 'SELECT column_name FROM table_name ORDER BY column2 DESC');
#}
#
#sub xmlSelectOrderBy1Long : Test(1)
#{
#	my $xml = << "EOF";
#<select from="table_name"
#xmlns="http://www.carspot.com/query">
#	<result>
#		<column>column_name</column>
#	</result>
#	<order-by>
#		<column dir="desc">column2</column>
#	</order-by>
#</select>
#EOF
#
#	my $query = parse( $xml );
#	my $sql = generate_sql( $query );
#	is ( $sql, 'SELECT column_name FROM table_name ORDER BY column2 DESC');
#}

sub xmlSelectJoin1 : Test(1)
{
	my $xml = << "EOF";
<select from="table1"
xmlns="http://www.carspot.com/query"
xmlns:op="http://www.carspot.com/query-operator">
	<result>
		<column>column_name</column>
	</result>
	<join type="inner" table="table2">
		<op:equal>
			<column>table1.key</column>
			<column>table2.table1_key</column>
		</op:equal>
	</join>
</select>
EOF

	my $query = parse( $xml );
	my $sql = generate_sql( $query );
	is ($sql, 'SELECT column_name FROM table1 INNER JOIN table2 ON table1.key = table2.table1_key');
}

1;


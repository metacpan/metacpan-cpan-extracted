#!/usr/bin/perl -w

package Local::Romani::Query::Update;
use base qw(Test::Class);

use DBIx::Romani::Query::Update;
use DBIx::Romani::Query::SQL::Generate;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Query::Comparison;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

=pod example

<update table="table_name">
	<value column="column_name">
		<literal>123</literal>
	<value>

	<where>
		<op:equal>
			<column>id</column>
			<literal>0</literal>
		</op:equal>
	</where>
</select>

=cut
sub queryUpdate1 : Test(1)
{
	my $query = DBIx::Romani::Query::Update->new( "table_name" );
	$query->set_value( 'column_name', DBIx::Romani::Query::SQL::Literal->new( '123' ) );
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'id' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( '0' ) );
	$query->set_where( $equal );

	# generate the SQL
	my $sql = generate_sql( $query );
	is ( $sql, "UPDATE table_name SET column_name = '123' WHERE id = '0'" );
}

sub queryUpdate1clone : Test(1)
{
	my $query = DBIx::Romani::Query::Update->new( "table_name" );
	$query->set_value( 'column_name', DBIx::Romani::Query::SQL::Literal->new( '123' ) );
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'id' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( '0' ) );
	$query->set_where( $equal );
	my $clone = $query->clone();

	# generate the SQL
	my $sql = generate_sql( $clone );
	is ( $sql, "UPDATE table_name SET column_name = '123' WHERE id = '0'" );
}

1;


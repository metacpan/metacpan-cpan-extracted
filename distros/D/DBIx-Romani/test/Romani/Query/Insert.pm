#!/usr/bin/perl -w

package Local::Romani::Query::Insert;
use base qw(Test::Class);

use DBIx::Romani::Query::Insert;
use DBIx::Romani::Query::SQL::Generate;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

=pod example

<insert into="table_name">
	<value column="column_name">
		<literal>123</literal>
	<value>
</select>

=cut
sub queryInsert1 : Test(1)
{
	my $query = DBIx::Romani::Query::Insert->new( "table_name" );
	$query->set_value( 'column_name', DBIx::Romani::Query::SQL::Literal->new( '123' ) );

	# generate the SQL
	my $sql = generate_sql( $query );
	is ( $sql, "INSERT INTO table_name (column_name) VALUES ('123')");
}

sub queryInsert1clone : Test(1)
{
	my $query = DBIx::Romani::Query::Insert->new( "table_name" );
	$query->set_value( 'column_name', DBIx::Romani::Query::SQL::Literal->new( '123' ) );
	my $clone = $query->clone();

	# generate the SQL
	my $sql = generate_sql( $clone );
	is ( $sql, "INSERT INTO table_name (column_name) VALUES ('123')");
}

1;


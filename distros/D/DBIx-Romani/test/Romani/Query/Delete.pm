#!/usr/bin/perl -w

package Local::Romani::Query::Delete;
use base qw(Test::Class);

use DBIx::Romani::Query::Delete;
use DBIx::Romani::Query::SQL::Generate;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

=pod example

<delete from="table_name">
	<where>
		<op:equal>
			<column>id</column>
			<literal>0</literal>
		</op:equal>
	</where>
</select>

=cut
sub queryDelete1 : Test(1)
{
	my $query = DBIx::Romani::Query::Delete->new( "table_name" );
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'id' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( '0' ) );
	$query->set_where( $equal );

	# generate the SQL
	my $sql = generate_sql( $query );
	is ( $sql, "DELETE FROM table_name WHERE id = '0'" );
}

sub queryDelete1clone : Test(1)
{
	my $query = DBIx::Romani::Query::Delete->new( "table_name" );
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'id' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( '0' ) );
	$query->set_where( $equal );
	my $clone = $query->clone();

	# generate the SQL
	my $sql = generate_sql( $clone );
	is ( $sql, "DELETE FROM table_name WHERE id = '0'" );
}

1;


#!/usr/bin/perl -w

package Local::Romani::Query::Function;
use base qw(Test::Class);

use DBIx::Romani::Query::Function::Count;
use DBIx::Romani::Query::Function::Now;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub functionCount : Test(1)
{
	my $count = DBIx::Romani::Query::Function::Count->new();
	$count->set_distinct( 1 );
	$count->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column_name' ) );

	my $s = generate_sql( $count );
	is( $s, "COUNT(DISTINCT column_name)" );
}

sub functionNow : Test(1)
{
	my $count = DBIx::Romani::Query::Function::Now->new();

	my $s = generate_sql( $count );
	is( $s, "NOW()" );
}

1;


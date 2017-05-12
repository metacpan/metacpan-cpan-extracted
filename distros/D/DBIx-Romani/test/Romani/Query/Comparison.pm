#!/usr/bin/perl -w

package Local::Romani::Query::Comparison;
use base qw(Test::Class);

use DBIx::Romani::Query::Where;
use DBIx::Romani::Query::Comparison;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub comparisonAnd : Test(1)
{
	my $op_eq1 = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$op_eq1->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column1' ) );
	$op_eq1->add( DBIx::Romani::Query::SQL::Literal->new( 'ABC' ) );

	my $op_eq2 = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$op_eq2->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column2' ) );
	$op_eq2->add( DBIx::Romani::Query::SQL::Literal->new( '123' ) );

	my $op_and = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );
	$op_and->add( $op_eq1 );
	$op_and->add( $op_eq2 );

	my $s = generate_sql( $op_and );
	is( $s, "column1 = 'ABC' AND column2 = '123'" );
}

sub comparisonOr : Test(1)
{
	my $op_eq1 = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$op_eq1->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column1' ) );
	$op_eq1->add( DBIx::Romani::Query::SQL::Literal->new( 'ABC' ) );

	my $op_eq2 = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$op_eq2->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column2' ) );
	$op_eq2->add( DBIx::Romani::Query::SQL::Literal->new( '123' ) );

	my $op_and = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::OR );
	$op_and->add( $op_eq1 );
	$op_and->add( $op_eq2 );

	my $s = generate_sql( $op_and );
	is( $s, "column1 = 'ABC' OR column2 = '123'" );
}

sub comparisonEqual : Test(1)
{
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column_name' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( 'ABC' ) );

	my $s = generate_sql( $equal );
	is( $s, "column_name = 'ABC'" );
}

sub comparisonNotEqual : Test(1)
{
	my $equal = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::NOT_EQUAL );
	$equal->add( DBIx::Romani::Query::SQL::Column->new( undef, 'column_name' ) );
	$equal->add( DBIx::Romani::Query::SQL::Literal->new( 'ABC' ) );

	my $s = generate_sql( $equal );
	is( $s, "column_name <> 'ABC'" );
}

sub comparisonGreaterThan : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::GREATER_THAN );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'price' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '21000' ) );

	my $s = generate_sql( $op );
	is( $s, "price > '21000'" );
}

sub comparisonGreaterEqual : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::GREATER_EQUAL );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'price' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '21000' ) );

	my $s = generate_sql( $op );
	is( $s, "price >= '21000'" );
}

sub comparisonLessThan : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::LESS_THAN );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'price' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '21000' ) );

	my $s = generate_sql( $op );
	is( $s, "price < '21000'" );
}

sub comparisonLessEqual : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::LESS_EQUAL );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'price' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '21000' ) );

	my $s = generate_sql( $op );
	is( $s, "price <= '21000'" );
}

sub comparisonLike : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::LIKE );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'name' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '%something%' ) );

	my $s = generate_sql( $op );
	is( $s, 'name LIKE \'%something%\'' );
}

sub comparisonNotLike : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::NOT_LIKE );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'name' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '%something%' ) );

	my $s = generate_sql( $op );
	is( $s, 'name NOT LIKE \'%something%\'' );
}

sub comparisonILike : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::ILIKE );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'name' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '%something%' ) );

	my $s = generate_sql( $op );
	is( $s, 'name ILIKE \'%something%\'' );
}

sub comparisonNotILike : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::NOT_ILIKE );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'name' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '%something%' ) );

	my $s = generate_sql( $op );
	is( $s, 'name NOT ILIKE \'%something%\'' );
}

sub comparisonIsNull : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::IS_NULL );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'optional_id' ) );

	my $s = generate_sql( $op );
	is( $s, 'optional_id IS NULL' );
}

sub comparisonIsNotNull : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::IS_NOT_NULL );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'optional_id' ) );

	my $s = generate_sql( $op );
	is( $s, 'optional_id IS NOT NULL' );
}

sub comparisonBetween : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::BETWEEN );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'year' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '1990' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '2001' ) );

	my $s = generate_sql( $op );
	is( $s, "year BETWEEN '1990' AND '2001'" );
}

sub comparisonIn : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::IN );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'year' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '2000' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '2001' ) );

	my $s = generate_sql( $op );
	is( $s, "year IN ('2000','2001')" );
}

sub comparisonNotIn : Test(1)
{
	my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::NOT_IN );
	$op->add( DBIx::Romani::Query::SQL::Column->new( undef, 'year' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '2000' ) );
	$op->add( DBIx::Romani::Query::SQL::Literal->new( '2001' ) );

	my $s = generate_sql( $op );
	is( $s, "year NOT IN ('2000','2001')" );
}

1;


#!/usr/bin/perl
use warnings;
use strict;

use Test::More 'no_plan';

my $class = 'Business::ISSN';

use_ok( $class, qw(is_valid_checksum) );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Things that should work
{
my @valid_issns = qw( 0355-4325 1553-667X );

foreach my $issn ( @valid_issns )
	{
	my $obj = $class->new( $issn );
	isa_ok( $obj, $class );
	ok( $obj->is_valid, "ISSN $issn is valid" );
	is( $obj->checksum, substr( $issn, -1, 1 ), "checksum returns right value" );
	is( $obj->as_string, $issn, "as_string matches original" );
	ok( is_valid_checksum( $issn ), "is_valid_checksum returns true for good issn" );
	ok( ! $obj->fix_checksum, "fix_checksum returns false for good issn" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Things that shouldn't work at all
{
my @invalid_issns = qw( 0355-4323 abcd pwer-1234 );

foreach my $issn ( @invalid_issns )
	{
	my $obj = $class->new( $issn );
	ok( ! eval { $obj->is_valid }, "ISSN $issn is not valid" );
	ok( ! is_valid_checksum( $issn ), "is_valid_checksum returns false for bad issn" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Things that we can fix
{
my @invalid_issns = (
	[ qw( 0355-4323 0355-4325 ) ],
	[ qw( 1553-6673 1553-667X ) ],	
	);

foreach my $pair ( @invalid_issns )
	{
	my $obj = $class->new( $pair->[0] );
	isa_ok( $obj, $class );
	ok( ! eval { $obj->is_valid }, "ISSN $pair->[0] is not valid" );
	ok( ! defined $obj->as_string, "as_string returns undef before we fix issn" );
	ok( ! is_valid_checksum( $pair->[0] ), "is_valid_checksum returns false for fixable issn" );

	ok( $obj->fix_checksum, "fix_checksum returns true" );
	ok( $obj->is_valid, "ISSN $pair->[1] is now valid" );
	is( $obj->as_string, $pair->[1], "as_string returns fixed issn" );
	}
}
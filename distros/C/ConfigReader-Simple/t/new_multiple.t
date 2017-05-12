#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'new_multiple';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with no arguments
{
my $rc = eval{ $class->$method() }; 
my $at = $@;
ok( length $at, "eval fails with no arguments" );
like( $at, qr/must be an array reference/, 
	"reports that it must be an array ref" );
like( $at, qr/Files/, 
	"reports that Files is the problem" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with Files argument which is not an array ref
{
my $rc = eval{ $class->$method( Files => 'a b c' ) }; 
my $at = $@;
ok( length $at, "eval fails with no arguments" );
like( $at, qr/must be an array reference/, 
	"reports that it must be an array ref" );
like( $at, qr/Files/, 
	"reports that Files is the problem" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with Files arguments which is an array ref, Keys that isn't
{
my $rc = eval{ $class->$method( Files => [], Keys => 'a b c' ) }; 
my $at = $@;
ok( length $at, "eval fails with no arguments" );
like( $at, qr/must be an array reference/, 
	"reports that it must be an array ref" );
like( $at, qr/Keys/, 
	"reports that Keys is the problem" );
}
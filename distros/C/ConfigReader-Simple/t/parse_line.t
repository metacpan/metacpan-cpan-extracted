#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'ConfigReader::Simple';
my $method = 'parse_line';

use_ok( $class );

ok( defined &ConfigReader::Simple::parse_line, "$method is defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a line that should work
{
my( $directive, $value ) = &ConfigReader::Simple::parse_line(
	"Cat = Buster" );
is( $directive, 'Cat'    );
is( $value,     'Buster' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a line that should fails
{
my $rc = eval { &ConfigReader::Simple::parse_line( "" ) };
my $at = $@;
ok( length $at, "eval of parse_line failed with empty string" );
like( $at, qr/Can't parse/, "Reports that it can't parse the string" );
}
#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More;


my $expect_exported =
{
	is_string       => 1,
	is_arrayref     => 1,
	is_hashref      => 1,
	is_coderef      => 1,
	is_number       => 1,
	assert_string   => 0,
	assert_arrayref => 0,
	assert_hashref  => 0,
	assert_coderef  => 0,
	assert_number   => 0,
	filter_string   => 0,
	filter_arrayref => 0,
	filter_hashref  => 0,
	filter_coderef  => 0,
	filter_number   => 0,
};

plan( tests => scalar( keys %$expect_exported ) + 1 );

use_ok( 'Data::Validate::Type', ':boolean_tests' );

while ( my ( $function, $exported ) = each( %$expect_exported ) )
{
	is(
		defined( &$function ) ? 1 : 0,
		$exported,
		"Function $function " . ( $exported ? "is" : "isn't") . " imported.",
	);
}

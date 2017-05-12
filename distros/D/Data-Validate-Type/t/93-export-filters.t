#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More;


my $expect_exported =
{
	is_string       => 0,
	is_arrayref     => 0,
	is_hashref      => 0,
	is_coderef      => 0,
	is_number       => 0,
	assert_string   => 0,
	assert_arrayref => 0,
	assert_hashref  => 0,
	assert_coderef  => 0,
	assert_number   => 0,
	filter_string   => 1,
	filter_arrayref => 1,
	filter_hashref  => 1,
	filter_coderef  => 1,
	filter_number   => 1,
};

plan( tests => scalar( keys %$expect_exported ) + 1 );

use_ok( 'Data::Validate::Type', ':filters' );

while ( my ( $function, $exported ) = each( %$expect_exported ) )
{
	is(
		defined( &$function ) ? 1 : 0,
		$exported,
		"Function $function " . ( $exported ? "is" : "isn't") . " imported.",
	);
}

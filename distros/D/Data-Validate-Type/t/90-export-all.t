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
	assert_string   => 1,
	assert_arrayref => 1,
	assert_hashref  => 1,
	assert_coderef  => 1,
	assert_number   => 1,
	filter_string   => 1,
	filter_arrayref => 1,
	filter_hashref  => 1,
	filter_coderef  => 1,
	filter_number   => 1,
};

plan( tests => scalar( keys %$expect_exported ) + 1 );

use_ok( 'Data::Validate::Type', ':all' );

while ( my ( $function, $exported ) = each( %$expect_exported ) )
{
	is(
		defined( &$function ) ? 1 : 0,
		$exported,
		"Function $function " . ( $exported ? "is" : "isn't") . " imported.",
	);
}

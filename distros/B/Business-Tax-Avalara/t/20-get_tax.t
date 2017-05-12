#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Business::Tax::Avalara;

# If you wish to run these tests, make an AvalaraConfig.pm in the lib directory that has a
# sub new, that returns a hash with the values you want to put into new().
# This file will not be checked in, and git is configured to ignore it.
eval 'use AvalaraConfig';
$@
	? plan( skip_all => 'Local connection information for Avalara required to run tests.' )
	: plan( tests => 6 );

my $config = AvalaraConfig->new();

my $avalara_gateway = Business::Tax::Avalara->new( %$config, debug => 0 );

ok(
	defined( $avalara_gateway ),
	'Create a new Business::Tax::Avalara object.',
) || diag( explain( $avalara_gateway ) );

my %lookup_data = (
	destination_address =>
		{
			line_1      => '11216 Waples Mill Road',
			city        => 'Fairfax',
			postal_code => '22030',
		},
	cart_lines =>
		[
			{
				sku         => '42ACE',
				quantity    => 1,
				amount      => '8.99',
				ref1        => 'abc',
				line_number => 3,
			},
			{
				sku         => '9FCE2',
				quantity    => 2,
				amount      => '38.98',
				ref1        => 'def',
				line_number => 4,
			}
		],
	commit => 1,
	document_code => 666,
);

ok (
	my $response = $avalara_gateway->get_tax( %lookup_data ),
	'Got data for test order 1.',
);

is (
	$response->{'TotalAmount'},
	47.97,
	'Total amount is correct.'
);

is (
	$response->{'TotalTax'},
	2.88,
	'Total Tax is correct.'
);

my %cart_line_tax =
(
	'3' => 0.54,
	'4' => 2.34,
);

foreach my $cart_line_id ( keys %{ $response->{'TaxLines'} } )
{
	is (
		$response->{'TaxLines'}->{ $cart_line_id }->{'Tax'},
		$cart_line_tax{ $cart_line_id },
		"Tax is correct for line $cart_line_id.",
	);
}

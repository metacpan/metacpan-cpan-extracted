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

# Create a unique doc_code
my $doc_code = time();

# First we need to create a tax lookup, so we can cancel it later.
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
	commit        => 1,
	document_code => $doc_code,
	document_type => 'SalesInvoice',
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

# Now we need to cancel it.
ok(
	$response = $avalara_gateway->cancel_tax(
		document_type => 'SalesInvoice',
		doc_code      => $doc_code,
		cancel_code   => 'DocVoided',
	),
	'Sent request to cancel tax.'
);

is(
	$response->{'CancelTaxResult'}->{'ResultCode'},
	'Success',
	'Tax was canceled.'
);

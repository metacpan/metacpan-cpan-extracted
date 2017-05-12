#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::Deep;

use Business::Tax::Avalara;

# If you wish to run these tests, make an AvalaraConfig.pm in the lib directory that has a
# sub new, that returns a hash with the values you want to put into new().
# This file will not be checked in, and git is configured to ignore it.
eval 'use AvalaraConfig';
$@
	? plan( skip_all => 'Local connection information for Avalara required to run tests.' )
	: plan( tests => 7 );

my $config = AvalaraConfig->new();

my $avalara_gateway = Business::Tax::Avalara->new( %$config, debug => 0 );

ok(
	defined( $avalara_gateway ),
	'Create a new Business::Tax::Avalara object.',
) || diag( explain( $avalara_gateway ) );

# Create a unique doc_code.
my $doc_code = time();
$doc_code =~ tr/0-9/a-j/;

# Determine dates we'll use as part of the test.
my $seconds_in_a_day = 60 * 60 * 24;
my $date_yesterday = iso_date( time() - $seconds_in_a_day );
my $date_today = iso_date();

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
				sku         => 'EC024',
				quantity    => 1,
				amount      => '10.00',
				ref1        => 'abc',
				line_number => 5,
			},
			{
				sku         => 'G524C',
				quantity    => 2,
				amount      => '30.00',
				discounted  => 1,
				ref1        => 'def',
				line_number => 6,
			},
			{
				sku         => 'shipping',
				quantity    => 1,
				amount      => '6.00',
				tax_code    => 'FR', # Freight
				line_number => 'shipping',
			},
		],
	discount      => '3.00',
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
	46.00,
	'Total amount is correct.'
);

is (
	$response->{'TotalTaxable'},
	37.00,
	'Total taxable amount is correct.'
);

is (
	$response->{'TotalTax'},
	2.22,
	'Total Tax is correct.'
);

# Now we need to cancel one item.
ok(
	$response = $avalara_gateway->get_tax(
		document_type       => 'ReturnInvoice',
		document_code       => $doc_code . '-01',
		commit              => 1,
		discount            => '-1.50',
		tax_override =>
		{
			reason            => 'Return',
			tax_override_type => 'TaxDate',
			tax_date          => $date_yesterday,
		},
		destination_address =>
		{
			line_1      => '11216 Waples Mill Road',
			city        => 'Fairfax',
			postal_code => '22030',
		},
		cart_lines =>
		[
			{
				sku          => 'G524C',
				quantity     => 1,
				amount       => '-15.00',
				discounted   => 1,
				ref1         => 'def',
				line_number  => 6,
			}
		],
	),
	'Sent request to refund one item.'
);

cmp_deeply(
	$response,
	superhashof(
		{
			'TaxDate'            => $date_yesterday,
			'DocDate'            => $date_today,
			'TotalAmount'        => -15,
			'TotalTaxable'       => -13.50,
			'TotalTaxCalculated' => -0.81,
			'TotalTax'           => -0.81,
		},
	),
	'Refunded item had tax removed.',
);

sub iso_date {
	my ($time) = @_;
	$time ||= time();
	my ($seconds, $minutes, $hours, $day, $month, $year) = localtime($time);
	return sprintf(
		"%s-%02d-%02d",
		$year + 1900,
		$month + 1,
		$day,
	);
}

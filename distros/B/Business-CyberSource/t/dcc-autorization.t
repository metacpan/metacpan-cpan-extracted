use strict;
use warnings;
use Test::More;
use Test::Method;
use Module::Runtime qw( use_module );

my $authc = use_module('Business::CyberSource::Request::Authorization');

my $billto
	= new_ok( use_module('Business::CyberSource::RequestPart::BillTo') => [{
		first_name  => 'Caleb',
		last_name   => 'Cushing',
		street1     => '8100 Cameron Road',
		city        => 'Austin',
		state       => 'TX',
		postal_code => '78753',
		country     => 'US',
		email       => 'xenoterracide@gmail.com',
	}]);

my $dto
	= new_ok( $authc => [{
		reference_code   => 'notarealcode',
		bill_to          => $billto,
		card => {
			account_number => '4111-1111-1111-1111',
			expiration     => {
				month => 6,
				year  => 2025,
			},
		},
		dcc_indicator    => 1,
		purchase_totals  => {
			total            => 1.00,
			currency         => 'USD',
			foreign_currency => 'JPY',
			foreign_amount   => 1.00, # not an accurate conversion
			exchange_rate    => 1.00,
			exchange_rate_timestamp => '20090101 00:00',
		},
	}]);

my %expected = (
	merchantReferenceCode => 'notarealcode',
	card => {
		accountNumber   => '4111111111111111',
		cardType        => '001',
		cvIndicator     => 0,
		expirationMonth => 6,
		expirationYear  => 2025,
	},
	ccAuthService => {
		run => 'true',
	},
	purchaseTotals => {
		currency              => 'USD',
		grandTotalAmount      => 1,
		foreignCurrency       => 'JPY',
		exchangeRateTimeStamp => '20090101 00:00',
		exchangeRate          => 1,
		foreignAmount         => 1,
	},
	billTo => {
		firstName  => 'Caleb',
		lastName   => 'Cushing',
		country    => 'US',
		street1    => '8100 Cameron Road',
		city       => 'Austin',
		state      => 'TX',
		postalCode => '78753',
		email      => 'xenoterracide@gmail.com',
	},
	dcc => {
		dccIndicator => 1,
	},
);

method_ok $dto, serialize => [], \%expected;

done_testing;

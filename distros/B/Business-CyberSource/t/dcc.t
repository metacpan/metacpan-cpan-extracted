use strict;
use warnings;
use Test::More;
use Test::Method;
use Module::Runtime qw( use_module );

my $dto
	= new_ok( use_module('Business::CyberSource::Request::DCC') => [{
		reference_code => 'notarealcode',
		card => {
			account_number => '4111-1111-1111-1111',
			expiration     => {
				month => 6,
				year  => 2025,
			},
		},
		purchase_totals => {
			currency         => 'USD',
			total            => '1.00',
			foreign_currency => 'JPY',
		},
	}]);

my %expected = (
	card => {
		accountNumber   => '4111111111111111',
		cardType        => '001',
		cvIndicator     => 0,
		expirationMonth => 6,
		expirationYear  => 2025,
	},
	ccDCCService => {
		run => 'true',
	},
	purchaseTotals => {
		currency         => 'USD',
		grandTotalAmount => '1.00',
		foreignCurrency  => 'JPY',
	},
	merchantReferenceCode => 'notarealcode',
);

method_ok $dto, serialize => [], \%expected;

done_testing;

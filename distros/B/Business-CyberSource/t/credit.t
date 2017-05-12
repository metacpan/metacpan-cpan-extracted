use strict;
use warnings;
use Test::More;
use Test::Method;

use Module::Runtime 'use_module';
use FindBin; use lib "$FindBin::Bin/lib";

my $t = use_module('Test::Business::CyberSource')->new;

my $dto
	= new_ok( use_module('Business::CyberSource::Request::Credit') => [{
		reference_code => 'notarealcode',
		bill_to =>
			$t->resolve( service => '/helper/bill_to' ),
		purchase_totals =>
			$t->resolve( service => '/helper/purchase_totals'),
		card =>
			$t->resolve( service => '/helper/card' ),
		ship_to =>
			$t->resolve( service => '/helper/ship_to' ),
        invoice_header => $t->resolve( service => '/helper/invoice_header' ),
        other_tax => $t->resolve( service => '/helper/other_tax' ),
        ship_from => $t->resolve( service => '/helper/ship_from' ),
	}]);

my %expected = (
	billTo => {
		firstName   => 'Caleb',
		lastName    => 'Cushing',
		country     => 'US',
		ipAddress   => '192.168.100.2',
		street1     => '2104 E Anderson Ln',
		state       => 'TX',
		email       => 'xenoterracide@gmail.com',
		city        => 'Austin',
		postalCode => '78752',
	},
	card => {
		accountNumber   => '4111111111111111',
		cardType        => '001',
		cvIndicator     => 1,
		cvNumber        => 1111,
		expirationMonth => 5,
		expirationYear  => 2025,
		fullName        => 'Caleb Cushing',
	},
	ccCreditService => {
		run => 'true',
	},
	purchaseTotals => {
		currency         => 'USD',
		grandTotalAmount => 3000.00,
                discountAmount   => 50.00,
                dutyAmount       => 10.00,
	},
	merchantReferenceCode => 'notarealcode',
	shipTo => {
		country     => 'US',
		street1     => '2104 E Anderson Ln',
		state       => 'TX',
		city        => 'Austin',
		postalCode  => '78752',
		firstName      => 'Caleb',
		lastName       => 'Cushing',
		street2        => 'N/A',
		phoneNumber    => '+1-512-555-0180',
		shippingMethod => 'none',
	},
    invoiceHeader => {
        purchaserVATRegistrationNumber => 'ATU99999999',
        userPO                         => '123456',
        vatInvoiceReferenceNumber      => '1234',
    },
    otherTax => {
        alternateTaxAmount => '0.10',
        alternateTaxIndicator => 1,
        vatTaxAmount => '0.10',
        vatTaxRate => '0.10',
    },
    shipFrom => {
        postalCode => '78752',
    },
);

method_ok $dto, serialize => [], \%expected;

done_testing;

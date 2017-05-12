use strict;
use warnings;
use Test::More;
use Test::Method;

use Module::Runtime qw( use_module );

my $capture = new_ok(
    use_module('Business::CyberSource::Request::Capture') => [
        {
            reference_code => 'not sending',
            service        => {
                request_id => 42,
            },
            purchase_totals => {
                total    => 2018.00,
                discount => 5.00,
                duty     => 1.00,
                currency => 'USD',
            },
            invoice_header => {
                purchaser_vat_registration_number => 'ATU99999999',
                user_po                           => '123456',
                vat_invoice_reference_number      => '1234',
            },
            ship_to => {
                country     => 'US',
                postal_code => '78701',
                city        => 'Austin',
                state       => 'TX',
                street1     => '306 E 6th',
                street2     => 'Dizzy Rooster',
            },
            other_tax => {
                alternate_tax_amount    => '1',
                alternate_tax_indicator => 1,
                vat_tax_amount          => '1',
                vat_tax_rate            => '0.04',
            },
            ship_from => {
                postal_code => '78752',
            },
        }
    ]
);

can_ok $capture, 'serialize';

my %expected = (
    merchantReferenceCode => 'not sending',
    purchaseTotals        => {
        grandTotalAmount => 2018.00,
        discountAmount   => 5.00,
        dutyAmount       => 1.00,
        currency         => 'USD',
    },
    ccCaptureService => {
        authRequestID => 42,
        run           => 'true',
    },
    invoiceHeader => {
        purchaserVATRegistrationNumber => 'ATU99999999',
        userPO                         => '123456',
        vatInvoiceReferenceNumber      => '1234',
    },
	shipTo => {
		country    => 'US',
		postalCode => '78701',
		city       => 'Austin',
		state      => 'TX',
		street1    => '306 E 6th',
		street2    => 'Dizzy Rooster',
	},
    otherTax => {
        alternateTaxAmount    => '1',
        alternateTaxIndicator => 1,
        vatTaxAmount          => '1',
        vatTaxRate            => '0.04'
    },
    shipFrom => {
        postalCode => '78752',
    },
);

method_ok $capture, serialize => [], \%expected;

done_testing;

use strict;
use warnings;
use Test::More;
use Test::Method;
use Module::Runtime qw( use_module );
use FindBin; use lib "$FindBin::Bin/lib";

my $dtc = use_module('Business::CyberSource::Request::Authorization');

my $t = new_ok( use_module('Test::Business::CyberSource') );

my @test_pairs = (
	[ '4111111111111111' => '001' ],
	[ '5555555555554444' => '002' ],
	[ '3566111111111113' => '004' ],
);

foreach ( @test_pairs ) {
	my ( $acct_num, $type_code ) = @{ $_ };

	my $dto = new_ok( $dtc => [{
		reference_code  => 12345,
		purchase_totals => $t->resolve( service => '/helper/purchase_totals'),
		bill_to         => $t->resolve( service  => '/helper/bill_to'),
		ship_to         => $t->resolve( service => '/helper/ship_to' ),
		card            => $t->resolve(
			service    => '/helper/card',
			parameters => {
				account_number => $acct_num,
			},
		),
        invoice_header => $t->resolve( service => '/helper/invoice_header' ),
        other_tax => $t->resolve( service => '/helper/other_tax' ),
        ship_from => $t->resolve( service => '/helper/ship_from' ),
	}]);

	can_ok $dto, 'serialize';

	isa_ok $dto->bill_to,         'Business::CyberSource::RequestPart::BillTo';
	isa_ok $dto->ship_to,         'Business::CyberSource::RequestPart::ShipTo';
	isa_ok $dto->purchase_totals, 'Business::CyberSource::RequestPart::PurchaseTotals';
	isa_ok $dto->card,            'Business::CyberSource::RequestPart::Card';
    isa_ok $dto->invoice_header,  'Business::CyberSource::RequestPart::InvoiceHeader';
    isa_ok $dto->other_tax,       'Business::CyberSource::RequestPart::OtherTax';
    isa_ok $dto->ship_from,       'Business::CyberSource::RequestPart::ShipFrom';

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
			postalCode  => '78752',
		},
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
		card => {
			accountNumber   => $acct_num,
			cardType        => $type_code,
			cvIndicator     => 1,
			cvNumber        => 1111,
			expirationMonth => 5,
			expirationYear  => 2025,
			fullName        => 'Caleb Cushing',
		},
		ccAuthService => {
			run => 'true',
		},
		purchaseTotals => {
			currency         => 'USD',
			grandTotalAmount => 3000.00,
			discountAmount   => 50.00,
			dutyAmount       => 10.00,
		},
		merchantReferenceCode => 12345,
        invoiceHeader => {
            purchaserVATRegistrationNumber => 'ATU99999999',
            userPO => '123456',
            vatInvoiceReferenceNumber => '1234',
        },
        otherTax => {
            alternateTaxAmount    => '0.10',
            alternateTaxIndicator => 1,
            vatTaxAmount          => '0.10',
            vatTaxRate            => '0.10',
        },
        shipFrom => {
            postalCode => '78752'
        }
	);

	method_ok $dto, serialize      => [], \%expected;
	method_ok $dto, reference_code => [], 12345;
}

done_testing;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );

my $Module = 'Business::CyberSource::RequestPart::InvoiceHeader';

my $invoiceheader = new_ok(
    use_module($Module) => [
        {
            purchaser_vat_registration_number => 'ATU99999999',
            user_po                      => '123456',
            vat_invoice_reference_number => '1234',
        }
    ]
);

does_ok $invoiceheader, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok $invoiceheader,  'serialize';
method_ok $invoiceheader,
  purchaser_vat_registration_number => [],
  'ATU99999999';
method_ok $invoiceheader, user_po => [], '123456';
method_ok $invoiceheader, vat_invoice_reference_number => [], '1234';

my %expected_serialized = (
    purchaserVATRegistrationNumber => 'ATU99999999',
    userPO                         => '123456',
    vatInvoiceReferenceNumber      => '1234',
);

method_ok $invoiceheader, serialize => [], \%expected_serialized;

my $invoiceheader1 = new_ok(
    use_module($Module) => [
        {
            purchaserVATRegistrationNumber => 'ATU99999999',
            userPO                         => '123456',
            vatInvoiceReferenceNumber      => '1234',
        }
    ]
);

done_testing;

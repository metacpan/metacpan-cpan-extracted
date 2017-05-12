use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );

my $Module = 'Business::CyberSource::RequestPart::OtherTax';

my $invoiceheader = new_ok(
    use_module($Module) => [
        {
            alternate_tax_amount    => '1',
            alternate_tax_indicator => 1,
            vat_tax_amount          => '1',
            vat_tax_rate            => '0.04',
        }
    ]
);

does_ok $invoiceheader, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok $invoiceheader,  'serialize';

method_ok $invoiceheader, alternate_tax_amount    => [], '1';
method_ok $invoiceheader, alternate_tax_indicator => [], 1;
method_ok $invoiceheader, vat_tax_amount          => [], '1';
method_ok $invoiceheader, vat_tax_rate            => [], '0.04';

my %expected_serialized = (
    alternateTaxAmount    => '1',
    alternateTaxIndicator => 1,
    vatTaxAmount          => '1',
    vatTaxRate            => '0.04',
);

method_ok $invoiceheader, serialize => [], \%expected_serialized;

my $invoiceheader1 = new_ok(
    use_module($Module) => [
        {
            alternateTaxAmount    => '1',
            alternateTaxIndicator => 1,
            vatTaxAmount          => '1',
            vatTaxRate            => '0.04',
        }
    ]
);

done_testing;

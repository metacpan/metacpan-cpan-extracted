package Test::Business::CyberSource;
use strict;
use warnings;
use namespace::autoclean;
use Module::Runtime qw( use_module );

use Test::Requires 'Bread::Board';
use Test::More;

use Moose;

extends 'Bread::Board::Container';

sub BUILD {
    my $self = shift;
    return container $self => as {
        container client => as {
            service 'user' => $ENV{PERL_BUSINESS_CYBERSOURCE_USERNAME}
              || 'test';
            service 'pass' => $ENV{PERL_BUSINESS_CYBERSOURCE_PASSWORD}
              || 'test';
            service test   => 1;
            service object => (
                class     => 'Business::CyberSource::Client',
                lifecycle => 'Singleton',
                block     => sub {
                    my $svc = shift;

                    if (   $svc->param('user') eq 'test'
                        || $svc->param('pass') eq 'test' )
                    {
                        plan skip_all => 'Unable to send with fake '
                          . 'credentials. Set both '
                          . 'PERL_BUSINESS_CYBERSOURCE_USERNAME ' . 'and '
                          . 'PERL_BUSINESS_CYBERSOURCE_PASSWORD '
                          . 'in the environment';

                        return;
                    }

                    my $client =
                      use_module('Business::CyberSource::Client')->new(
                        {
                            user => $svc->param('user'),
                            pass => $svc->param('pass'),
                            test => $svc->param('test'),
                        }
                      );

                    return $client;
                },
                dependencies => {
                    user => depends_on('user'),
                    pass => depends_on('pass'),
                    test => depends_on('test'),
                },
            );
        };

        container card => as {
            service holder        => 'Caleb Cushing';
            service security_code => '1111';
            service object        => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('../helper/security_code'),
                    holder        => depends_on('../helper/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '4111111111111111',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );
        };

        container helper => as {
            container services => as {
                service first_name    => 'Caleb';
                service last_name     => 'Cushing';
                service street        => '2104 E Anderson Ln';
                service city          => 'Austin';
                service state         => 'TX';
                service country       => 'US';
                service postal_code   => '78752';
                service email         => 'xenoterracide@gmail.com';
                service ip            => '192.168.100.2';
                service currency      => 'USD';
                service holder        => 'Caleb Cushing';
                service security_code => '1111';
                service purchaser_vat_registration_number => 'ATU99999999';
                service user_po                           => '123456';
                service vat_invoice_reference_number      => '1234';
                service alternate_tax_amount              => '0.10';
                service alternate_tax_indicator           => 1;
                service vat_tax_amount                    => '0.10';
                service vat_tax_rate                      => '0.10';
                service street2         => 'N/A';
                service shipping_method => 'none';
                service phone_number    => '+1-512-555-0180';
            };

            service card => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('services/security_code'),
                    holder        => depends_on('services/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '4111111111111111',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );

            service card_amex => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('services/security_code'),
                    holder        => depends_on('services/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '378282246310005',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );

            service card_visa => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('services/security_code'),
                    holder        => depends_on('services/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '4111111111111111',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );

            service card_mastercard => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('services/security_code'),
                    holder        => depends_on('services/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '5555555555554444',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );

            service card_discover => (
                class        => 'Business::CyberSource::RequestPart::Card',
                dependencies => {
                    security_code => depends_on('services/security_code'),
                    holder        => depends_on('services/holder'),
                },
                parameters => {
                    account_number => {
                        isa     => 'Str',
                        default => '6011111111111117',
                    },
                    expiration => {
                        isa     => 'HashRef',
                        default => {
                            month => 5,
                            year  => 2025,
                        },
                    },
                },
            );

            service bill_to => (
                class        => 'Business::CyberSource::RequestPart::BillTo',
                dependencies => {
                    first_name  => depends_on('services/first_name'),
                    last_name   => depends_on('services/last_name'),
                    street      => depends_on('services/street'),
                    city        => depends_on('services/city'),
                    state       => depends_on('services/state'),
                    postal_code => depends_on('services/postal_code'),
                    email       => depends_on('services/email'),
                    ip          => depends_on('services/ip'),
                    country     => depends_on('services/country'),
                },
            );

            service invoice_header => (
                class => 'Business::CyberSource::RequestPart::InvoiceHeader',
                dependencies => {
                    purchaser_vat_registration_number =>
                      depends_on('services/purchaser_vat_registration_number'),
                    user_po => depends_on('services/user_po'),
                    vat_invoice_reference_number =>
                      depends_on('services/vat_invoice_reference_number'),
                },
            );

            service ship_to => (
                class        => 'Business::CyberSource::RequestPart::ShipTo',
                dependencies => {
                    street1     => depends_on('services/street'),
                    country     => depends_on('services/country'),
                    postal_code => depends_on('services/postal_code'),
                    state       => depends_on('services/state'),
                    city        => depends_on('services/city'),
                    # optional fields to check sandbox
                    first_name      => depends_on('services/first_name'),
                    last_name       => depends_on('services/last_name'),
                    street2         => depends_on('services/street2'),
                    phone_number    => depends_on('services/phone_number'),
                    shipping_method => depends_on('services/shipping_method'),
                },
            );

            service purchase_totals => (
                class => 'Business::CyberSource::RequestPart::PurchaseTotals',
                dependencies => {
                    currency => depends_on('services/currency'),
                },
                parameters => {
                    total => {
                        isa     => 'Num',
                        default => 3000.00,
                    },
                    discount => {
                        isa     => 'Num',
                        default => 50.00,
                    },
                    duty => {
                        isa     => 'Num',
                        default => 10.00,
                    },
                },
            );

            service other_tax => (
                class        => 'Business::CyberSource::RequestPart::OtherTax',
                dependencies => {
                    alternate_tax_amount =>
                      depends_on('services/alternate_tax_amount'),
                    alternate_tax_indicator =>
                      depends_on('services/alternate_tax_indicator'),
                    vat_tax_amount => depends_on('services/vat_tax_amount'),
                    vat_tax_rate   => depends_on('services/vat_tax_rate'),
                },
            );

            service ship_from => (
                class        => 'Business::CyberSource::RequestPart::ShipFrom',
                dependencies => {
                    postal_code => depends_on('services/postal_code'),
                },
            );

        };

        container request => as {
            service reference_code =>
              ( block => sub { return 'test-' . time }, );
            service authorization => (
                class        => 'Business::CyberSource::Request::Authorization',
                dependencies => {
                    card            => depends_on('/helper/card'),
                    reference_code  => depends_on('reference_code'),
                    purchase_totals => depends_on('/helper/purchase_totals'),
                    bill_to         => depends_on('/helper/bill_to'),
                    invoice_header  => depends_on('/helper/invoice_header'),
                    other_tax       => depends_on('/helper/other_tax'),
                    ship_from       => depends_on('/helper/ship_from'),
                },
                parameters => {
                    card => {
                        isa      => 'Business::CyberSource::RequestPart::Card',
                        optional => 1,
                    },
                    purchase_totals => {
                        isa =>
                          'Business::CyberSource::RequestPart::PurchaseTotals',
                        optional => 1,
                    },
                    business_rules => {
                        isa =>
                          'Business::CyberSource::RequestPart::BusinessRules',
                        optional => 1,
                    },
                    invoice_header => {
                        isa =>
                            'Business::CyberSource::RequestPart::InvoiceHeader',
                            optional => 1,
                    },
                    other_tax => {
                        isa =>
                            'Business::CyberSource::RequestPart::OtherTax',
                            optional => 1,
                    },
                    ship_from => {
                        isa =>
                            'Business::CyberSource::RequestPart::ShipFrom',
                            optional => 1,
                    },
					ship_to => {
						isa => 'Business::CyberSource::RequestPart::ShipTo',
						optional => 1,
					},
                },
            );
        };
    };
}

has '+name' => ( default => sub { __PACKAGE__ }, );

__PACKAGE__->meta->make_immutable;
1;

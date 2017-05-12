#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MooseX::Params::Validate;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires qw( Path::FindDev );
use lib Path::FindDev::find_dev($FindBin::Bin)->child( 't', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object' );

subtest "Visa" => sub {
    test_double_capture_auth( { card_type => 'visa' } );
    test_capture_declined_auth( { card_type => 'visa' } );
};

subtest "American Express" => sub {
    test_double_capture_auth( { card_type => 'amex' } );
    test_capture_declined_auth( { card_type => 'amex' } );
};

subtest "MasterCard" => sub {
    test_double_capture_auth( { card_type => 'mastercard' } );
    test_capture_declined_auth( { card_type => 'mastercard' } );
};

subtest "Discover" => sub {
    test_double_capture_auth( { card_type => 'discover' } );
    test_capture_declined_auth( { card_type => 'discover' } );
};

sub test_double_capture_auth {
    my (%args) = validated_hash( \@_, card_type => { isa => 'Str' }, );

    subtest "Double Capture an Auth" => sub {
        my $res = $client->submit(
            $t->resolve(
                service    => '/request/authorization',
                parameters => {
                    card => $t->resolve(
                        service => '/helper/card_' . $args{card_type}
                    ),
                }
            )
        );

        isa_ok( $res, 'Business::CyberSource::Response' );

        my $initial_capture = new_ok(
            use_module('Business::CyberSource::Request::Capture') => [
                {
                    reference_code => $res->reference_code,
                    service        => {
                        request_id => $res->request_id,
                    },
                    purchase_totals => {
                        total    => $res->auth->amount,
                        currency => $res->currency,
                    },
                    ship_to => $t->resolve( service => '/helper/ship_to' ),
                    invoice_header =>
                      $t->resolve( service => '/helper/invoice_header' ),
                    other_tax => $t->resolve( service => '/helper/other_tax' ),
                    ship_from => $t->resolve( service => '/helper/ship_from' ),
                }
            ]
        );

        my $initial_capture_response = $client->submit($initial_capture);
        is( $initial_capture_response->decision,
            'ACCEPT', "Initial Capture Successful" );

        my $duplicate_capture = new_ok(
            use_module('Business::CyberSource::Request::Capture') => [
                {
                    reference_code => $res->reference_code,
                    service        => {
                        request_id => $res->request_id,
                    },
                    purchase_totals => {
                        total    => $res->auth->amount,
                        currency => $res->currency,
                    },
                    ship_to => $t->resolve( service => '/helper/ship_to' ),
                    invoice_header =>
                      $t->resolve( service => '/helper/invoice_header' ),
                    other_tax => $t->resolve( service => '/helper/other_tax' ),
                    ship_from => $t->resolve( service => '/helper/ship_from' ),
                }
            ]
        );

        my $duplicate_capture_response = $client->submit($duplicate_capture);

        is( $duplicate_capture_response->decision, 'REJECT', 'check decision' );
        is( $duplicate_capture_response->reason_code, 242,
            'check reason_code' );

        ok( $duplicate_capture_response->request_id,
            'check request_id exists' );
    };

    return;
}

sub test_capture_declined_auth {
    my (%args) = validated_hash( \@_, card_type => { isa => 'Str' }, );

    subtest "Capture a Declined Auth" => sub {
        my $res = $client->submit(
            $t->resolve(
                service    => '/request/authorization',
                parameters => {
                    card => $t->resolve(
                        service => '/helper/card_' . $args{card_type}
                    ),
                    purchase_totals => $t->resolve(
                        service    => '/helper/purchase_totals',
                        parameters => {
                            total => 3000.04,
                        }
                    ),
                }
            )
        );

        isa_ok( $res, 'Business::CyberSource::Response' );

        my $declined_capture = new_ok(
            use_module('Business::CyberSource::Request::Capture') => [
                {
                    reference_code => $res->reference_code,
                    service        => {
                        request_id => $res->request_id,
                    },
                    purchase_totals => {
                        total    => 3000.04,
                        currency => 'USD',
                    },
                    ship_to => $t->resolve( service => '/helper/ship_to' ),
                    invoice_header =>
                      $t->resolve( service => '/helper/invoice_header' ),
                    other_tax => $t->resolve( service => '/helper/other_tax' ),
                }
            ]
        );

        my $declined_capture_response = $client->submit($declined_capture);

        is( $declined_capture_response->decision, 'REJECT', 'check decision' );
        is( $declined_capture_response->reason_code, 102, 'check reason_code' );

        ok( $declined_capture_response->request_id, 'check request_id exists' );
    };

    return;
}

done_testing;

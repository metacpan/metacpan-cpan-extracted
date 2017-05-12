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
    test_successful_capture( { card_type => 'visa' } );
};

subtest "America Express" => sub {
    test_successful_capture( { card_type => 'amex' } );
};

subtest "MasterCard" => sub {
    test_successful_capture( { card_type => 'mastercard' } );
};

subtest "Discover" => sub {
    test_successful_capture( { card_type => 'discover' } );
};

done_testing;

sub test_successful_capture {
    my (%args) = validated_hash( \@_, card_type => { isa => 'Str' }, );

    my $res = $client->submit(
        $t->resolve(
            service    => '/request/authorization',
            parameters => {
                card =>
                  $t->resolve( service => '/helper/card_' . $args{card_type} ),
            }
        )
    );

    isa_ok( $res, 'Business::CyberSource::Response' );

    my $capture = new_ok(
        use_module('Business::CyberSource::Request::Capture') => [
            {
                reference_code => $res->reference_code,
                service        => {
                    request_id => $res->request_id,
                },
                purchase_totals => {
                    total    => $res->auth->amount,
                    discount => '50.00',              # optional
                    duty     => '10.00',              # optional
                    currency => $res->currency,
                },
                ship_to => $t->resolve( service => '/helper/ship_to' ),
                invoice_header =>
                  $t->resolve( service => '/helper/invoice_header' ),
                other_tax =>
                  $t->resolve( service => '/helper/other_tax' ),
                ship_form => 
                  $t->resolve( service => '/helper/ship_from' ),
            }
        ]
    );

    my $cres = $client->submit($capture);

    isa_ok( $cres, 'Business::CyberSource::Response' )
      or diag( $capture->trace->printResponse );

    is( $cres->decision,             'ACCEPT',  'check decision' );
    is( $cres->reason_code,          100,       'check reason_code' );
    is( $cres->currency,             'USD',     'check currency' );
    is( $cres->capture->amount,      '3000.00', 'check amount' );
    is( $cres->capture->reason_code, 100,       'check capture_reason_code' );

    ok( $cres->capture->reconciliation_id, 'reconciliation_id exists' );
    ok( $cres->request_id,                 'check request_id exists' );

    return;
}

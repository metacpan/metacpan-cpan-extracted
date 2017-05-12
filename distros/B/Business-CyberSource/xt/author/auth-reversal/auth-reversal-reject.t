#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client   = $t->resolve( service => '/client/object'    );
my $authrevc = use_module('Business::CyberSource::Request::AuthReversal');

subtest "Reverse an Authorization with a Bad Request ID" => sub {
    my $auth_res
        = $client->submit(
            $t->resolve( service => '/request/authorization' )
        );

    my $rev_req
        = new_ok( $authrevc => [{
            reference_code => $auth_res->reference_code,
            service => {
                request_id => '834',
            },
            purchase_totals => {
                total    => $auth_res->auth->amount,
                currency => $auth_res->currency,
            },
        }]);

    my $rev_res = $client->submit( $rev_req );

    is( $rev_res->decision, 'REJECT', 'check decision' );
    is( $rev_res->reason_code, 102, 'check reason_code' );

    ok( $rev_res->request_token, 'request token exists' );
};

subtest "Reverse an already reversed Authorization" => sub {
    my $auth_res
        = $client->submit(
            $t->resolve( service => '/request/authorization' )
        );

    my $initial_auth_reversal_request = new_ok( $authrevc => [{
        reference_code => $auth_res->reference_code,
        service => {
            request_id => $auth_res->request_id,
        },
        purchase_totals => {
            total    => $auth_res->auth->amount,
            currency => $auth_res->currency,
        },
    }]);

    my $initial_auth_reversal_response = $client->submit( $initial_auth_reversal_request );

    my $duplicate_auth_reversal_request = new_ok( $authrevc => [{
        reference_code => $auth_res->reference_code,
        service => {
            request_id => $auth_res->request_id,
        },
        purchase_totals => {
            total    => $auth_res->auth->amount,
            currency => $auth_res->currency,
        },
    }]);

    my $duplicate_auth_reversal_response = $client->submit($duplicate_auth_reversal_request);

    is( $duplicate_auth_reversal_response->decision, 'REJECT', 'check decision' );
    is( $duplicate_auth_reversal_response->reason_code, 243, 'check reason_code' );

    ok( $duplicate_auth_reversal_response->request_token, 'request token exists' );
};

subtest "Reverse an already captured Authorization" => sub {
    my $auth_res
        = $client->submit(
            $t->resolve( service => '/request/authorization' )
        );

    my $capture_request = new_ok(
        use_module('Business::CyberSource::Request::Capture') => [{
            reference_code => $auth_res->reference_code,
            service => {
                request_id => $auth_res->request_id,
            },
            purchase_totals => {
                total => $auth_res->auth->amount,
                currency => $auth_res->currency,
            }
        }]
    );

    my $capture_response = $client->submit($capture_request);
    is($capture_response->decision, 'ACCEPT', "Accepted capture attempt");

    my $auth_reversal_request = new_ok( $authrevc => [{
        reference_code => $auth_res->reference_code,
        service => {
            request_id => $auth_res->request_id,
        },
        purchase_totals => {
            total    => $auth_res->auth->amount,
            currency => $auth_res->currency,
        },
    }]);

    my $auth_reversal_response = $client->submit( $auth_reversal_request );

    is( $auth_reversal_response->decision, 'REJECT', 'check decision' );
    is( $auth_reversal_response->reason_code, 243, 'check reason_code' );

    ok( $auth_reversal_response->request_token, 'request token exists' );
};

subtest "Reverse a declined Authorization" => sub {
    my $auth_res = $client->submit(
        $t->resolve(
            service    => '/request/authorization',
            parameters => {
                purchase_totals => $t->resolve(
                    service => '/helper/purchase_totals',
                    parameters => {
                        total => '3000.04',
                    }
                ),
            },
        )
    );

    my $rev_req
        = new_ok( $authrevc => [{
            reference_code => $auth_res->reference_code,
            service => {
                request_id => '834',
            },
            purchase_totals => {
                total    => '3000.04',
                currency => 'USD',
            },
        }]);

    my $rev_res = $client->submit( $rev_req );

    is( $rev_res->decision, 'REJECT', 'check decision' );
    is( $rev_res->reason_code, 102, 'check reason_code' );

    ok( $rev_res->request_token, 'request token exists' );
};

done_testing;

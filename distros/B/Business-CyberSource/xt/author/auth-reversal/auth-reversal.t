#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MooseX::Params::Validate;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object'    );

my $authrevc = use_module('Business::CyberSource::Request::AuthReversal');

subtest "Visa" => sub {
    test_successful_authorization_reversal({ card_type => 'visa' });
};

subtest "MasterCard" => sub {
    test_successful_authorization_reversal({ card_type => 'mastercard' });
};

subtest "Discover" => sub {
    test_successful_authorization_reversal({ card_type => 'discover' });
};

subtest "American Express (Does Not Permit Auth Reversals)" => sub {
    my $res = $client->submit(
        $t->resolve(
            service => '/request/authorization',
            parameters => {
                card => $t->resolve( service => '/helper/card_amex' ),
            },
        )
    );

    my $rev_req
        = new_ok( $authrevc => [{
            reference_code => $res->reference_code,
            service => {
                request_id => $res->request_id,
            },
            purchase_totals => {
                total    => $res->auth->amount,
                currency => $res->currency,
            },
        }]);

    my $rev = $client->submit( $rev_req );

    isa_ok( $rev, 'Business::CyberSource::Response' );

    ok( $rev, 'reversal response exists' );

    TODO: {
        local $TODO = 'Handle AMEX Can Not Auth Reverse';

        is( $rev->decision, 'REJECT', 'check decision' );
        is( $rev->reason_code, 231, 'check reason_code' );
        is( $rev->auth_reversal->reason_code , 231, 'check capture_reason_code' );
    };
};

done_testing;

sub test_successful_authorization_reversal {
    my (%args) = validated_hash(
        \@_,
        card_type => { isa => 'Str' },
    );

    my $res = $client->submit(
        $t->resolve(
            service => '/request/authorization',
            parameters => {
                card => $t->resolve( service => '/helper/card_' . $args{card_type} ),
            },
        )
    );

    my $rev_req
        = new_ok( $authrevc => [{
            reference_code => $res->reference_code,
            service => {
                request_id => $res->request_id,
            },
            purchase_totals => {
                total    => $res->auth->amount,
                currency => $res->currency,
            },
        }]);

    my $rev = $client->submit( $rev_req );

    isa_ok( $rev, 'Business::CyberSource::Response' );

    ok( $rev, 'reversal response exists' );

    is( $rev->decision, 'ACCEPT', 'check decision' );
    is( $rev->reason_code, 100, 'check reason_code' );
    is( $rev->currency, 'USD', 'check currency' );
    is( $rev->auth_reversal->amount, '3000.00', 'check amount' );
    is( $rev->auth_reversal->reason_code , 100, 'check capture_reason_code' );

    ok( $rev->auth_reversal->datetime, 'datetime exists' );

    return;
};

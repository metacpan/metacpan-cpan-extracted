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

my $client = $t->resolve( service => '/client/object' );

subtest "American Express" => sub {
    test_declined_authorization({ card_type => 'amex' });
    test_expired_card({ card_type => 'amex' });
};

subtest "Visa" => sub {
    test_declined_authorization({ card_type => 'visa' });
    test_expired_card({ card_type => 'visa' });
};

subtest "MasterCard" => sub {
    test_declined_authorization({ card_type => 'mastercard' });
    test_expired_card({ card_type => 'mastercard' });
};

subtest "Discover" => sub {
    test_declined_authorization({ card_type => 'discover' });
    test_expired_card({ card_type => 'discover' });
};

done_testing;

sub test_expired_card {
    my (%args) = validated_hash(
        \@_,
        card_type => { isa => 'Str' },
    );

    subtest "Test Expired Card" => sub {
        my $ret
            = $client->submit(
                $t->resolve(
                    service    => '/request/authorization',
                    parameters => {
                        card            => $t->resolve(
                            service => '/helper/card_' . $args{card_type}
                        ),
                        purchase_totals => $t->resolve(
                            service    => '/helper/purchase_totals',
                            parameters => {
                                total => 3000.37, # magic make me expired
                            },
                        ),
                        ship_to => $t->resolve( service => '/helper/ship_to' ),
                    },
                )
            );

        isa_ok( $ret, 'Business::CyberSource::Response' );

        is( $ret->is_accept,                 0,       'success'            );
        is( $ret->decision,                 'REJECT', 'decision'           );
        is( $ret->reason_code,               202,     'reason_code'        );
        is( $ret->auth->processor_response, '54',     'processor response' );

        ok( $ret->request_id,               'request_id exists'            );
        ok( $ret->request_token,            'request_token exists'         );

        is(
            $ret->reason_text,
            'Expired card. You might also receive this if the expiration date you '
                . 'provided does not match the date the issuing bank has on file'
                ,
            'reason_text',
        );
    };

    return;
};

sub test_declined_authorization {
    my (%args) = validated_hash(
        \@_,
        card_type => { isa => 'Str' },
    );

    subtest "Test Declined Authorization" => sub {
        my $ret
            = $client->submit(
                $t->resolve(
                    service    => '/request/authorization',
                    parameters => {
                        card            => $t->resolve(
                            service => '/helper/card_' . $args{card_type}
                        ),
                        purchase_totals => $t->resolve(
                            service    => '/helper/purchase_totals',
                            parameters => {
                                total => 3000.04, # magic 201
                            },
                        ),
                        ship_to => $t->resolve( service => '/helper/ship_to' ),
                    },
                )
            );

        isa_ok( $ret, 'Business::CyberSource::Response' );


        is( $ret->decision,       'REJECT', 'decision'       );
        is( $ret->reason_code,     201,     'reason_code'    );
        is(
            $ret->reason_text,
            'The issuing bank has questions about the request. You do not '
            . 'receive an authorization code programmatically, but you might '
            . 'receive one verbally by calling the processor'
            ,
            'reason_text',
        );
    };

    return;
}

#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Method;
use Type::Params    qw( compile     );
use Types::Standard qw( HashRef Str );

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object'    );

subtest "American Express" => sub {
    test_successful_authorization({
        card_type => 'amex',
    });
    test_commerce_indicator({
        card_type => 'amex',
    });
};

subtest "Visa" => sub {
    test_successful_authorization({
        card_type => 'visa',
    });
    test_commerce_indicator({
        card_type => 'visa',
    });
};

subtest "MasterCard" => sub {
    test_successful_authorization({
        card_type => 'mastercard',
    });
    test_commerce_indicator({
        card_type => 'mastercard',
    });
};

subtest "Discover" => sub {
    test_successful_authorization({
        card_type => 'discover',
    });
    test_commerce_indicator({
        card_type => 'discover',
    });
};


done_testing;

sub test_commerce_indicator {
    state $check = compile( HashRef[Str] );
    my ( $args ) = $check->( @_ );

    my $card_type = $args->{card_type};

    my $auth_req = $t->resolve(
        service    => '/request/authorization',
        parameters => {
            card =>
              $t->resolve( service => '/helper/card_' . $args->{card_type} ),
        }
    );

    $auth_req->service->commerce_indicator('recurring');

    ok( $client->submit($auth_req)->is_accept,
        "commerce_indicator 'recurring' accepted for card_type => $card_type"
    );

    return;
}

sub test_successful_authorization {
    state $check = compile( HashRef[Str] );
    my ( $args ) = $check->( @_ );

    my $ret
        = $client->submit(
            $t->resolve(
                service => '/request/authorization',
                parameters => {
                    card    => $t->resolve( service => '/helper/card_' . $args->{card_type} ),
                    ship_to => $t->resolve( service => '/helper/ship_to' ),
                }
            )
        );

    isa_ok $ret,                 'Business::CyberSource::Response';
    isa_ok $ret->auth->datetime, 'DateTime';
    isa_ok $ret->trace,          'XML::Compile::SOAP::Trace';

    method_ok $ret,       has_trace     => [], bool(1);
    method_ok $ret,       is_accept     => [], 1;
    method_ok $ret,       decision      => [], 'ACCEPT';
    method_ok $ret,       reason_code   => [], 100;
    method_ok $ret,       currency      => [], 'USD';
    method_ok $ret,       reason_text   => [], 'Successful transaction';
    method_ok $ret,       request_id    => [], re('\d+');
    method_ok $ret,       request_token => [], re('[[:xdigit:]]+');
    method_ok $ret->auth, amount        => [], '3000.00';
    method_ok $ret->auth, auth_code     => [], '831000';
    method_ok $ret->auth, auth_record   => [], re('[[:xdigit:]]+');
    method_ok $ret->auth, processor_response => [], '00';
    method_ok $ret->auth, avs_code      => [], 'Y';
    method_ok $ret->auth, avs_code_raw  => [], 'Y';

    ok ! ref $ret->request_id, 'request_id is not a reference';

    if($args->{card_type} eq "amex") {
        method_ok($ret->auth, ev_email            => [], 'Y' );
        method_ok($ret->auth, ev_phone_number     => [], 'Y' );
        method_ok($ret->auth, ev_postal_code      => [], 'Y' );
        method_ok($ret->auth, ev_name             => [], 'Y' );
        method_ok($ret->auth, ev_street           => [], 'Y' );
        method_ok($ret->auth, ev_email_raw        => [], 'Y' );
        method_ok($ret->auth, ev_phone_number_raw => [], 'Y' );
        method_ok($ret->auth, ev_postal_code_raw  => [], 'Y' );
        method_ok($ret->auth, ev_name_raw         => [], 'Y' );
        method_ok($ret->auth, ev_street_raw       => [], 'Y' );
    }
    else {
        method_ok $ret->auth, has_ev_email            => [], bool(0);
        method_ok $ret->auth, has_ev_phone_number     => [], bool(0);
        method_ok $ret->auth, has_ev_postal_code      => [], bool(0);
        method_ok $ret->auth, has_ev_name             => [], bool(0);
        method_ok $ret->auth, has_ev_street           => [], bool(0);
        method_ok $ret->auth, has_ev_email_raw        => [], bool(0);
        method_ok $ret->auth, has_ev_phone_number_raw => [], bool(0);
        method_ok $ret->auth, has_ev_postal_code_raw  => [], bool(0);
        method_ok $ret->auth, has_ev_name_raw         => [], bool(0);
        method_ok $ret->auth, has_ev_street_raw       => [], bool(0);
    }

    return;
}


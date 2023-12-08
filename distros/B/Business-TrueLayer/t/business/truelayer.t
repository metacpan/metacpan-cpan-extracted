#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer' );
isa_ok(
    my $TrueLayer = Business::TrueLayer->new(
        client_id => 'TL-CLIENT-ID',
        client_secret => 'super-secret-client-secret',
        host => '/dev/null',
        payment_host => '/dev/random',
    ),
    'Business::TrueLayer'
);

isa_ok(
    $TrueLayer->authenticator,
    'Business::TrueLayer::Authenticator'
);

subtest '->merchant_accounts' => sub {

    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_get = sub {
        return {
            items => [ {
                'id' => '5b7adbf4-f289-48a7-b451-bc236443397c',
                'available_balance_in_minor' => 90000,
                'currency' => 'GBP',
                'current_balance_in_minor' => 100000,
                'account_holder_name' => 'btdt',
                'account_identifiers' => [
                    {
                        'account_number' => '00033171',
                        'sort_code' => '040668',
                        'type' => 'sort_code_account_number'
                    },
                    {
                        'iban' => 'GB05CLRB04066800033171',
                        'type' => 'iban'
                    },
                ],
            }
        ] };
    };

    isa_ok(
        ( $TrueLayer->merchant_accounts )[0],
        'Business::TrueLayer::MerchantAccount',
    );
};

subtest '->create_payment' => sub {

    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_post = sub {
        return {
            "id" => "SOMEID",
            "user" => {
                "id" => "ABABAB-CDCDCD-EFEFEF-GHGHGH"
            },
            "resource_token" => "a-secret-token",
            "status" => "authorization_required"
        };
    };

    my $args = _payment_args();

    isa_ok(
        my $Payment = $TrueLayer->create_payment( $args ),
        'Business::TrueLayer::Payment',
    );

    is( $Payment->id,'SOMEID','payment->id' );
    is( $Payment->status,'authorization_required','payment->status' );
    is( $Payment->resource_token,'a-secret-token','payment->resource_token' );
    is( $Payment->user->id,'ABABAB-CDCDCD-EFEFEF-GHGHGH','payment->user->id' );
    is( $Payment->host,'/dev/null','->host passed to Payment object' );
    is( $Payment->payment_host,'/dev/random','->payment_host passed to Payment object' );
};

subtest '->get_payment' => sub {

    no warnings qw/ once redefine /;
    *Business::TrueLayer::Request::api_get = sub {
        return _payment_args();
    };

    isa_ok(
        my $Payment = $TrueLayer->get_payment( 'SOMEID' ),
        'Business::TrueLayer::Payment',
    );

    is( $Payment->id,'SOMEID','payment->id' );
    is( $Payment->status,'authorization_required','payment->status' );
    is( $Payment->resource_token,'a-secret-token','payment->resource_token' );
    is( $Payment->user->id,'ABABAB-CDCDCD-EFEFEF-GHGHGH','payment->user->id' );
    is( $Payment->host,'/dev/null','->host passed to Payment object' );
    is( $Payment->payment_host,'/dev/random','->payment_host passed to Payment object' );
};

# taken from https://docs.truelayer.com/docs/create-a-payment
sub _payment_args {
    return {
        "id" => "SOMEID",
        "currency"       => "GBP",
        "payment_method" => {
            "type"               => "bank_transfer",
            "provider_selection" => {
                "type"   => "user_selected",
                "filter" => {
                    "countries"         => ["DE"],
                    "release_channel"   => "general_availability",
                    "customer_segments" => ["retail"]
                },
                "scheme_selection" => {
                    "type"               => "instant_only",
                    "allow_remitter_fee" => 0,
                }
            },
            "beneficiary" => {
                "type"                => "merchant_account",
                "verification"        => { "type" => "automated" },
                "merchant_account_id" => "AB8FA060-3F1B-4AE8-9692-4AA3131020D0",
                "account_holder_name" => "Ben Eficiary",
                "reference"           => "payment-ref"
            }
        },
        "user" => {
            "id"            => "ABABAB-CDCDCD-EFEFEF-GHGHGH",
            "name"          => "Remi Terr",
            "email"         => 'remi.terr@aol.com',
            "phone"         => "+447777777777",
            "date_of_birth" => "1990-01-31"
        },
        "amount_in_minor" => 1,
        "resource_token" => "a-secret-token",
        "status" => "authorization_required"
    };
}

subtest '->test_signature' => sub {

    # "no content"
    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_post = sub {
        return;
    };

    ok( $TrueLayer->test_signature,'->test_signature' );
};

done_testing();

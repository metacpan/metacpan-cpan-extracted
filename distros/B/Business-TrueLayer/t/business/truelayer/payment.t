#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Payment' );

my $Payment = Business::TrueLayer::Payment->new(
    # taken from https://docs.truelayer.com/docs/create-a-payment
    {
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
                },
                "remitter" => {
                    "account_holder_name" => "John Sandbridge",
                    "account_identifier" => {
                        "type" => "sort_code_account_number",
                        "sort_code" => "500000",
                        "account_number" => "12345601"
                    },
                },
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
            "id"            => "f9b48c9d-176b-46dd-b2da-fe1a2b77350c",
            "name"          => "Remi Terr",
            "email"         => 'remi.terr@aol.com',
            "phone"         => "+447777777777",
            "date_of_birth" => "1990-01-31"
        },
        "amount_in_minor" => 1,

        # optiona
        "metadata" => "#payment #12345 XYZ",
        "related_products" => "foo bar",
    }
);

isa_ok(
    $Payment,
    'Business::TrueLayer::Payment',
);

is( $Payment->currency,'GBP','->currency' );
is( $Payment->amount_in_minor,1,'->amount_in_minor' );
ok( ! $Payment->status,'! ->status' );
ok( ! $Payment->resource_token,'! ->resource_token' );

is( $Payment->metadata,"#payment #12345 XYZ",'->metadata' );
is( $Payment->related_products,"foo bar",'->related_products' );

isa_ok( $Payment->user,'Business::TrueLayer::User' );
isa_ok( $Payment->payment_method,'Business::TrueLayer::Payment::Method' );
isa_ok(
    $Payment->payment_method->beneficiary,
    'Business::TrueLayer::Beneficiary'
);

isa_ok(
    $Payment->payment_method->provider,
    'Business::TrueLayer::Provider'
);

isa_ok(
    $Payment->payment_method->provider->remitter,
    'Business::TrueLayer::Remitter'
);

ok( ! $Payment->authorization_required,'! ->authorization_required' );
ok( ! $Payment->authorizing,'! ->authorizing' );
ok( ! $Payment->authorized,'! ->authorized' );
ok( ! $Payment->executed,'! ->executed' );
ok( ! $Payment->settled,'! ->settled' );
ok( ! $Payment->failed,'! ->failed' );

done_testing();

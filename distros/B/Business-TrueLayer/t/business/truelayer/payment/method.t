#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Payment::Method' );

my $Method = Business::TrueLayer::Payment::Method->new(
    # taken from https://docs.truelayer.com/docs/create-a-payment
    {
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
    }
);

isa_ok(
    $Method,
    'Business::TrueLayer::Payment::Method',
);

is( $Method->type,'bank_transfer','->type' );
isa_ok( $Method->beneficiary,'Business::TrueLayer::Beneficiary' );
isa_ok( $Method->provider,'Business::TrueLayer::Provider' );

done_testing();

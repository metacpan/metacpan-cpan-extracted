#!perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib $Bin;

use Test::Most;
use Test::Warnings;
use Test::Credentials;
use Business::TrueLayer;

plan skip_all => "set TRUELAYER_CREDENTIALS"
    if ! $ENV{TRUELAYER_CREDENTIALS};

my $TrueLayer = Business::TrueLayer->new(
    my $creds = Test::Credentials->new->TO_JSON,
);

my $Payment = $TrueLayer->create_payment({
    "currency"       => "GBP",
    "payment_method" => {
        "type"               => "bank_transfer",
        "provider_selection" => {
            "type"   => "user_selected",
            "filter" => {
                "countries"         => ["GB"],
                "release_channel"   => "general_availability",
                "customer_segments" => ["retail"]
            },
            "scheme_selection" => {
                "type"               => "instant_preferred",
            }
        },
        "beneficiary" => {
            "type"                => "merchant_account",
            "merchant_account_id" => "5b7adbf4-f289-48a7-b451-bc236443397c",
            "account_holder_name" => "btdt",
            "reference"           => "payment-ref-$$"
        }
    },
    "user" => {
        "name"          => "Remi Terr",
        "email"         => 'remi.terr@aol.com',
        "phone"         => "+447777777777",
        "date_of_birth" => "1990-01-31"
    },
    "amount_in_minor" => 1000
});

isa_ok( $Payment,'Business::TrueLayer::Payment' );
ok( $Payment->id,'->id' );
ok( $Payment->status,'->status' );
ok( $Payment->resource_token,'->resource_token' );
ok( $Payment->user->id,'->user->id' );

note $Payment->hosted_payment_page_link(
    'http://localhost:3000/callback',
);

$Payment = $TrueLayer->get_payment( $Payment->id );
is( $Payment->status,'authorization_required','->get_payment' );
ok( $Payment->authorization_required,'->authorization_required' );

done_testing();

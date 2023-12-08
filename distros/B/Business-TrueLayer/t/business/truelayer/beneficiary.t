#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Beneficiary' );

my $Beneficiary = Business::TrueLayer::Beneficiary->new(
    # taken from https://docs.truelayer.com/docs/create-a-payment
    {
        "type"                => "merchant_account",
        "verification"        => { "type" => "automated" },
        "merchant_account_id" => "AB8FA060-3F1B-4AE8-9692-4AA3131020D0",
        "account_holder_name" => "Ben Eficiary",
        "reference"           => "payment-ref"
    }
);

isa_ok(
    $Beneficiary,
    'Business::TrueLayer::Beneficiary',
);

is( $Beneficiary->type,'merchant_account','->type' );
cmp_deeply(
    $Beneficiary->verification,
    { type => 'automated' }
    ,'->verification'
);
is( $Beneficiary->merchant_account_id,'AB8FA060-3F1B-4AE8-9692-4AA3131020D0','->type' );
is( $Beneficiary->account_holder_name,'Ben Eficiary','->account_holder_name' );
is( $Beneficiary->reference,'payment-ref','->reference' );

done_testing();

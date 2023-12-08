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

my @merchant_accounts = $TrueLayer->merchant_accounts;
isa_ok( $merchant_accounts[0],'Business::TrueLayer::MerchantAccount' );
isa_ok(
    $merchant_accounts[0]->account_identifiers->[0],
    'Business::TrueLayer::MerchantAccount::Identifier'
);

done_testing();

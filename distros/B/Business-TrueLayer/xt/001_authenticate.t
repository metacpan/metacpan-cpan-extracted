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

ok(
    my $access_token = $TrueLayer->access_token,
    'got an access token'
);

done_testing();

#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Provider::Scheme' );

my $Scheme = Business::TrueLayer::Provider::Scheme->new(
    "type"               => "instant_only",
    "allow_remitter_fee" => 0,
);

isa_ok(
    $Scheme,
    'Business::TrueLayer::Provider::Scheme',
);

is( $Scheme->type,'instant_only','->type' );
ok( ! $Scheme->allow_remitter_fee,'! ->allow_remitter_fee' );

done_testing();

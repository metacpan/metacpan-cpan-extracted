#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Provider::Filter' );

my $Filter = Business::TrueLayer::Provider::Filter->new(
    "countries"         => ["DE"],
    "release_channel"   => "general_availability",
    "customer_segments" => ["retail"]
);

isa_ok(
    $Filter,
    'Business::TrueLayer::Provider::Filter',
);

is( $Filter->countries->[0],'DE','countries' );
is( $Filter->release_channel,'general_availability','release_channel' );
is( $Filter->customer_segments->[0],'retail','customer_segments' );

done_testing();

#!/bin/env perl

# UPS_Online RateRequest - some basic "shop" tests.

use strict;
use warnings;
use Test::More;
use Carp;
use Business::Shipping;

plan skip_all => ''
    unless Business::Shipping::Config::calc_req_mod('USPS_Online');
plan skip_all => 'No credentials'
    unless $ENV{UPS_USER_ID}
        and $ENV{UPS_PASSWORD}
        and $ENV{UPS_ACCESS_KEY};
plan 'no_plan';

{
    my $rr_shop = Business::Shipping->rate_request(
        service    => 'shop',
        shipper    => 'UPS_Online',
        from_zip   => '98682',
        to_zip     => '98270',
        weight     => 5.00,
        user_id    => $ENV{UPS_USER_ID},
        password   => $ENV{UPS_PASSWORD},
        access_key => $ENV{UPS_ACCESS_KEY}
    );

    ok(defined $rr_shop,
        'Business::Shipping->rate_request returned an object for \'Shop\'.');

    $rr_shop->go() or die $rr_shop->user_error();

    foreach my $shipper (@{ $rr_shop->results }) {
        foreach my $rate (@{ $shipper->{rates} }) {
            ok($rate->{charges},
                "$shipper->{name} $rate->{name}: $rate->{charges_formatted}");
        }
    }
}

{
    my $rr_shop = Business::Shipping->rate_request(
        service        => 'shop',
        shipper        => 'UPS_Online',
        from_zip       => '98683',
        to_zip         => '98270',
        weight         => 450.00,
        to_residential => 0,
        user_id        => $ENV{UPS_USER_ID},
        password       => $ENV{UPS_PASSWORD},
        access_key     => $ENV{UPS_ACCESS_KEY},
        shipper_number => $ENV{UPS_SHIPPER_NUMBER},
    );

    ok(defined $rr_shop,
        'Business::Shipping->rate_request returned an object for \'Shop\'.');

    $rr_shop->go() or die $rr_shop->user_error();

    #use Data::Dumper;
    #die(Dumper($rr_shop));

    foreach my $shipper (@{ $rr_shop->results }) {
        foreach my $rate (@{ $shipper->{rates} }) {
            ok($rate->{charges},
                "hundredweight shop: $shipper->{name} $rate->{name}: $rate->{charges_formatted}"
            );
        }
    }
}

1;

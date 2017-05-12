#!/usr/bin/env perl

# Test that Log4perl logs the correct messages at the right time.

use strict;
use warnings;
use Test::More;
eval { require Test::Log4perl };
plan skip_all => 'Test::Log4perl not installed.'
    if $@;

plan 'no_plan';

import Test::Log4perl;

# we also have a simplified version:
SKIP: {
    skip 'Under development.';

    my $foo = Test::Log4perl->expect(
        ['Business.Shipping.RateRequest.validate', info => qr/required = /]);
    use Business::Shipping;

    Business::Shipping->log_level('info');

    my $rr = Business::Shipping->rate_request(shipper => 'UPS_Offline');

    ok($rr, 'Got Rate Request');

    $rr->init(
        service        => 'gndcom',
        weight         => '330',
        from_zip       => '98682',
        to_zip         => '87110',
        to_city        => 'Albuquerque',
        tier           => 3,
        to_residential => 0,
    );

    $rr->execute();

}

# $foo goes out of scope; this triggers the test.

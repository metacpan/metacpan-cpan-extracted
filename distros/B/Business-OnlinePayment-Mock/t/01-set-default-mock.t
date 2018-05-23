#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 3;
use Test::Deep;
use Module::Runtime qw( use_module );

my $mock_client = new_ok( use_module('Business::OnlinePayment'), ['Mock'] );

cmp_deeply(
    $Business::OnlinePayment::Mock::default_mock,
    {
        error_message => 'Declined',
        is_success    => 0,
        error_code    => 100,
        order_number  => ignore(),
    },
    'Sets the mock default on the mock object'
);

$mock_client->set_default_mock({
    error_message => 'foobar',
    is_success    => 123,
    error_code    => 123,
    order_number  => 123,
});

cmp_deeply(
    $Business::OnlinePayment::Mock::default_mock,
    {
        error_message => 'foobar',
        is_success    => 123,
        error_code    => 123,
        order_number  => 123,
    },
    'Sets the mock default on the mock object'
) or diag explain $Business::OnlinePayment::Mock::default_mock;

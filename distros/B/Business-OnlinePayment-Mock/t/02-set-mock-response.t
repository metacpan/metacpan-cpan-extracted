#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 2;
use Test::Deep;
use Module::Runtime qw( use_module );

my $mock_client = new_ok( use_module('Business::OnlinePayment'), ['Mock'] );

$mock_client->set_mock_response({
    action        => 'Credit',
    card_number   => '4111111111111111',
    error_message => 'foobar',
    is_success    => 123,
    error_code    => 123,
    order_number  => 123,
});

cmp_deeply(
    $Business::OnlinePayment::Mock::mock_responses,
    {
        Credit => {
            '4111111111111111' => {
                error_message => 'foobar',
                is_success    => 123,
                error_code    => 123,
                order_number  => 123,
            }
        }
    },
    'Sets the mock response if supplied'
) or diag explain $Business::OnlinePayment::Mock::mock_responses;

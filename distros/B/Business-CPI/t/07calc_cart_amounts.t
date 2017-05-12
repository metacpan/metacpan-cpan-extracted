#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use Business::CPI;

my $cpi = Business::CPI->new(
    gateway      => 'Test',
    receiver_id  => 'receiver@andrewalker.net',
    currency     => 'BRL',
);

ok($cpi, 'the object was is defined');
isa_ok($cpi, 'Business::CPI::Gateway::Test');

{
    my $cart = $cpi->new_cart({
        buyer => {
            email => 'buyer@andrewalker.net',
            name  => 'Mr. Buyer',
        },

        items => [
            {
                id => 'Item 1 - 1 x R$ 2',
                price => 2.00,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
            {
                id => 'Item 2 - 5 x R$ 8',
                price => 8.00,
                quantity => 5,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
            {
                id => 'Item 3 - 2 x R$ 13.50',
                price => 13.50,
                quantity => 2,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
        ],

        discount => 0.13,
        tax      => 0.07,
        handling => 0.02,
    });

    ok($cart, 'the object was is defined');
    isa_ok($cart, 'Business::CPI::Base::Cart');

    is($cart->discount, '0.13', '$cart->discount is R$ 0.13');
    is($cart->tax, '0.07', '$cart->tax is R$ 0.07');
    is($cart->handling, '0.02', '$cart->handling is R$ 0.02');
    is($cart->shipping, '0.00', '$cart->shipping is R$ 0.00');

    is($cart->get_total_shipping(), 36, 'total shipping is 36.00');
    is($cart->get_total_amount(), 104.96, 'total amount is 104.96');
}

{
    my $cart = $cpi->new_cart({

        buyer => {
            email => 'buyer@andrewalker.net',
            name  => 'Mr. Buyer',
        },

        items => [
            {
                id => 'Item 1 - 1 x R$ 2',
                price => 2.00,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
            {
                id => 'Item 2 - 5 x R$ 8',
                price => 8.00,
                quantity => 5,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
            {
                id => 'Item 3 - 2 x R$ 13.50',
                price => 13.50,
                quantity => 2,
                shipping => 7.00,
                shipping_additional => 3.00,
            },
        ],

        shipping => 33,
    });

    ok($cart, 'the object was is defined');
    isa_ok($cart, 'Business::CPI::Base::Cart');

    is($cart->discount, '0.00', '$cart->discount is R$ 0');
    is($cart->tax, '0.00', '$cart->tax is R$ 0');
    is($cart->handling, '0.00', '$cart->handling is R$ 0');
    is($cart->shipping, '33.00', '$cart->shipping is R$ 33.00');

    is($cart->get_total_shipping(), 69.0, 'total shipping is 69.00');
    is($cart->get_total_amount(), 138.0, 'total amount is 138.00');
}

done_testing;

#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

use Test::More;
use FindBin '$Bin';
use Business::CPI::Gateway::MercadoPago;
use Encode;

unless ( $ENV{'MP_CLIENT_ID'} and $ENV{'MP_CLIENT_SECRET'} ) {
    plan skip_all =>
      'Testing this module needs MP_CLIENT_ID and MP_CLIENT_SECRET.';
}

sub get_value_for {
    my ( $form, $name ) = @_;
    return $form->look_down( _tag => 'input', name => $name )->attr('value');
}

ok(
    my $cpi = Business::CPI::Gateway::MercadoPago->new(
        receiver_email => $ENV{'MP_CLIENT_ID'},
        token          => $ENV{'MP_CLIENT_SECRET'},
        currency       => 'BRL',
        back_url       => 'https://www.xx.com',
    ),
    'build $cpi'
);

isa_ok( $cpi, 'Business::CPI::Gateway::MercadoPago' );

ok( $cpi->access_token, 'Check access_token' );

ok(
    my $cart = $cpi->new_cart(
        {
            buyer => {
                name  => 'Mr. Buyer',
                email => 'sender@andrewalker.net',
            }
        }
    ),
    'build $cart'
);

isa_ok( $cart, 'Business::CPI::Cart' );

ok(
    my $item = $cart->add_item(
        {
            id          => 1,
            quantity    => 1,
            price       => 200,
            description => 'my desc',
        }
    ),
    'build $item'
);

ok( $cart->get_checkout_code('123') );

done_testing;


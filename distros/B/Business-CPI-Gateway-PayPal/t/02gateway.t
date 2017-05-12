#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Business::CPI::Gateway::PayPal;

sub get_value_for {
    my ($form, $name) = @_;
    return $form->look_down(_tag => 'input', name => $name )->attr('value');
}

ok(my $cpi = Business::CPI::Gateway::PayPal->new(
    receiver_id => 'andre@andrewalker.net',
), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::PayPal');

ok(my $cart = $cpi->new_cart({
    buyer => {
        name  => 'Mr. Buyer',
        email => 'sender@andrewalker.net',
    }
}), 'build $cart');

ok($cart->does('Business::CPI::Role::Cart'), 'the cart does the correct role');

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 1,
    price       => 200,
    description => 'my desc',
}), 'build $item');

ok(my $form = $cart->get_form_to_pay(123), 'get form to pay');
isa_ok($form, 'HTML::Element');

is(get_value_for($form, 'item_number_1'), '1', 'item id 1');
is(get_value_for($form, 'amount_1'),      '200.00', 'item amount 1');
is(get_value_for($form, 'quantity_1'),    '1', 'item quantity 1');
is(get_value_for($form, 'invoice'),       '123', 'invoice');
is(get_value_for($form, 'email'),         'sender@andrewalker.net', 'sender email');

done_testing;

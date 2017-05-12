#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Business::CPI;
use Business::CPI::Base::Account;

my $cpi = Business::CPI->new(
    gateway      => 'Test',
    receiver_id  => 'receiver@andrewalker.net',
);

isa_ok($cpi, 'Business::CPI::Gateway::Test');

my $cart = $cpi->new_cart({
    buyer => {
        email              => 'buyer@andrewalker.net',
        name               => 'Mr. Buyer',
        address_street     => 'Street 1',
        address_number     => '25b',
        address_district   => 'My neighbourhood',
        address_complement => 'Apartment 05',
        address_city       => 'Happytown',
        address_state      => 'SP',
        address_country    => 'BR',
    },
    receivers => [
        {
            gateway_id => 'receiver1',
            percent_amount => 5,
        },
        {
            account => Business::CPI::Base::Account->new(gateway_id => 'receiver2', _gateway => $cpi),
            percent_amount => 5,
        },
    ],
});

$cart->add_item({
    id          => 1,
    description => 'Sample item',
    price       => 200,
    quantity    => 10,
});

ok(my $form = $cart->get_form_to_pay('pay123'), 'get form');
isa_ok($form, 'HTML::Element');
is( get_value_for($form, 'receiver_email'), 'receiver@andrewalker.net', 'form value receiver_email is correct' );
is( get_value_for($form, 'payment_id'),     'pay123',                   'form value payment_id is correct' );
is( get_value_for($form, 'buyer_name'),     'Mr. Buyer',                'form value buyer_name is correct' );
is( get_value_for($form, 'buyer_email'),    'buyer@andrewalker.net',    'form value buyer_email is correct' );
is( get_value_for($form, 'encoding'),       'UTF-8',                    'form value encoding is correct' );

is( get_value_for($form, 'item1_id'),        '1',                        'form value item1_id is correct' );
is( get_value_for($form, 'item1_desc'),      'Sample item',              'form value item1_desc is correct' );
is( get_value_for($form, 'item1_price'),     '200.00',                   'form value item1_price is correct' );
is( get_value_for($form, 'item1_qty'),       '10',                       'form value item1_qty is correct' );

is( get_value_for($form, 'receiver1_id'),      'receiver1',              'form value receiver1_id is correct' );
is( get_value_for($form, 'receiver1_percent'), '5.00',                   'form value receiver1_percent is correct' );

is( get_value_for($form, 'receiver2_id'),      'receiver2',              'form value receiver2_id is correct' );
is( get_value_for($form, 'receiver2_percent'), '5.00',                   'form value receiver2_percent is correct' );

done_testing;

sub get_value_for {
    my ($form, $name) = @_;
    return $form->look_down(_tag => 'input', name => $name )->attr('value');
}

#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Business::CPI;

my $cpi = Business::CPI->new(
    gateway      => 'Test',
    receiver_id  => 'receiver@andrewalker.net',
    currency     => 'BRL',
    checkout_url => '',
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
    handling => 10,
    tax      => 15.3,
    discount => 50,
});

$cart->add_item({
    id                  => 1,
    description         => 'Sample item',
    price               => 200,
    quantity            => 10,
    shipping            => 3,
    shipping_additional => 2,
    weight              => 1.5,
});

ok(my $form = $cart->get_form_to_pay('pay123'), 'get form');
isa_ok($form, 'HTML::Element');
is( get_value_for($form, 'receiver_email'), 'receiver@andrewalker.net', 'form value receiver_email is correct' );
is( get_value_for($form, 'currency'),       'BRL',                      'form value currency is correct' );
is( get_value_for($form, 'payment_id'),     'pay123',                   'form value payment_id is correct' );
is( get_value_for($form, 'buyer_name'),     'Mr. Buyer',                'form value buyer_name is correct' );
is( get_value_for($form, 'buyer_email'),    'buyer@andrewalker.net',    'form value buyer_email is correct' );
is( get_value_for($form, 'encoding'),       'UTF-8',                    'form value encoding is correct' );

# OTHER COSTS
is( get_value_for($form, 'handling_amount'), '10.00',                   'form value handling_amount is correct' );
is( get_value_for($form, 'tax_amount'),      '15.30',                   'form value tax_amount is correct' );
is( get_value_for($form, 'discount_amount'), '50.00',                   'form value discount_amount is correct' );

# SHIPPING
is( get_value_for($form, 'shipping_address'),  'Street 1, 25b',                   'form value shipping_address is correct' );
is( get_value_for($form, 'shipping_address2'), 'My neighbourhood - Apartment 05', 'form value shipping_address2 is correct' );
is( get_value_for($form, 'shipping_city'),     'Happytown',                       'form value shipping_city is correct' );
is( get_value_for($form, 'shipping_state'),    'SP',                              'form value shipping_state is correct' );
is( get_value_for($form, 'shipping_country'),  'br',                              'form value shipping_country is correct' );

is( get_value_for($form, 'item1_id'),        '1',                        'form value item1_id is correct' );
is( get_value_for($form, 'item1_desc'),      'Sample item',              'form value item1_desc is correct' );
is( get_value_for($form, 'item1_price'),     '200.00',                   'form value item1_price is correct' );
is( get_value_for($form, 'item1_qty'),       '10',                       'form value item1_qty is correct' );
is( get_value_for($form, 'item1_shipping'),  '3.00',                     'form value item1_shipping is correct' );
is( get_value_for($form, 'item1_shipping2'), '2.00',                     'form value item1_shipping_additional is correct' );
is( get_value_for($form, 'item1_weight'),    '1500',                     'form value item1_weight is correct' );

is_deeply( [ $form->look_down(_tag => 'input', name => 'shipping_zip' ) ], [], 'empty zip means no field in the form' );

done_testing;

sub get_value_for {
    my ($form, $name) = @_;
    return $form->look_down(_tag => 'input', name => $name )->attr('value');
}

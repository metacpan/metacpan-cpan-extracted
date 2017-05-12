#!perl -T

use strict;
use warnings;

use Test::More;
use Business::Colissimo;

my ($colissimo, $tracking, $sorting, $tracking_expected, $sorting_expected,
    $len, @mode_values, $mode, $value_ref, $country, $international);

@mode_values = ([access_f => {product_code => '8L', 
                              international => 0, 
                              options => {}}],
                [expert_f => {product_code => '8V', international => 0, options => {}}],
                [expert_om => {product_code => '7A', international => 0, options => {}}],
                [expert_om => {product_code => '7A', international => 0, 
                               options => {ack_receipt => 1},
                               sorting => '7A1722409000011234000493',
                 }],
                [expert_om => {product_code => '7A', international => 0, 
                               options => {ack_receipt => 1, duty_free => 1},
                               sorting => '7A1722409000011234000691',
                 }],
                [expert_om => {product_code => '7A', international => 0, 
                               options => {cod => 1},
                               sorting => '7A1722409000011234000196',
                 }],
                [expert_i => {product_code => 'CY', international => 1, options => {}}],
                [expert_i_kpg => {product_code => 'EY', international => 1, options => {}}],
    );

plan tests => 9 * scalar @mode_values;

for (@mode_values) {
    my ($mode, $value_ref) = @$_;
    
    $country = 'BE';
    
    $colissimo = Business::Colissimo->new(mode => $mode, %{$value_ref->{options}});

    # test whether international is set correctly
    $international = $colissimo->international;

    ok($international == $value_ref->{international}, 'international test')
        || diag "wrong value for international: $international";

    if ($international) {
        $colissimo->parcel_number('01234567');
        $colissimo->postal_code('1234');
        $colissimo->country_code($country);
    }
    else {
        $colissimo->parcel_number('0123456789');
        $colissimo->postal_code('72240');
    }

    $colissimo->customer_number('900001');
    $colissimo->weight(12340);

    # check tracking barcode
    $tracking = $colissimo->barcode('tracking');

    $len = length($tracking);

    ok($len == 13, 'tracking barcode length test')
        || diag "length for mode $mode is $len instead of 13: $tracking";

    if ($international) {
        $tracking_expected = $value_ref->{product_code} . '012345675FR';
    }
    else {
        $tracking_expected = $value_ref->{product_code} . '01234567895';
    }
    
    ok($tracking eq $tracking_expected, 'tracking barcode number test')
	|| diag "barcode $tracking instead of $tracking_expected";

    # check tracking barcode with spacing
    $tracking = $colissimo->barcode('tracking', spacing => 1);

    $len = length($tracking);

    ok($len == 16, 'tracking barcode length with spacing test')
	|| diag "length $len instead of 16: $tracking";

    if ($international) {
        $tracking_expected = $value_ref->{product_code} . ' 0123 4567 5FR';
    }
    else {
        $tracking_expected = $value_ref->{product_code} . ' 01234 56789 5';
    }
    
    ok($tracking eq $tracking_expected, 'tracking barcode number with spacing test')
	|| diag "barcode $tracking instead of $tracking_expected";

    # check sorting barcode
    $sorting = $colissimo->barcode('sorting');

    $len = length($sorting);

    ok($len == 24, "sorting barcode test for mode $mode")
	|| diag "length $len instead of 24: $sorting";

    if ($value_ref->{sorting}) {
        $sorting_expected = $value_ref->{sorting};
    }
    elsif ($international) {
        $sorting_expected = $value_ref->{product_code} . '2BE1239000011234000073';
    }
    else {
        $sorting_expected = $value_ref->{product_code} . '1722409000011234000097';
    }
    
    ok($sorting eq $sorting_expected, "shipping barcode number test for mode $mode")
	|| diag "barcode $sorting instead of $sorting_expected";

    # check sorting barcode with spacing
    $sorting = $colissimo->barcode('sorting', spacing => 1);

    $len = length($sorting);

    ok($len == 28, 'sorting barcode number test with spacing')
	|| diag "length $len instead of 24: $sorting";

    if ($value_ref->{sorting}) {
        $sorting_expected = join(' ', substr($value_ref->{sorting}, 0, 3),
                                 substr($value_ref->{sorting}, 3, 5),
                                 substr($value_ref->{sorting}, 8, 6),
                                 substr($value_ref->{sorting}, 14, 4),
                                 substr($value_ref->{sorting}, 18, 6));
    } elsif ($international) {
        $sorting_expected = $value_ref->{product_code} . '2 BE123 900001 1234 000073';
    }
    else {
        $sorting_expected = $value_ref->{product_code} . '1 72240 900001 1234 000097';
    }
    
    ok($sorting eq $sorting_expected, 'shipping barcode number test')
	|| diag "barcode $sorting instead of $sorting_expected";
}

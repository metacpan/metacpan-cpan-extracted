#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Business::CPI::Gateway::PayPal::IPN;

my $IS_SUCCESS = 1;
my $POSTED = 0;

my %params = (
    'verify_sign'            => 'bunch-of-undecipherable-characters',
    'num_cart_items'         => '2',
    'payer_id'               => 'ETKP7B8LV2CAW',
    'residence_country'      => 'DE',
    'mc_shipping2'           => '0.00',
    'mc_handling'            => '0.00',
    'tax1'                   => '0.00',
    'receiver_email'         => 'test@test.com',
    'item_number1'           => 'store-provided-number1',
    'payment_type'           => 'instant',
    'business'               => 'test@test.com',
    'payment_status'         => 'Completed',
    'mc_shipping1'           => '0.00',
    'txn_type'               => 'cart',
    'payment_fee'            => '',
    'charset'                => 'windows-1252',
    'mc_handling1'           => '0.00',
    'payment_date'           => '12:06:46 Dec 18, 2012 PST',
    'quantity2'              => '1',
    'invoice'                => '55a002e2-494d-11e2-9db7-002219548a94',
    'quantity1'              => '1',
    'mc_fee'                 => '0.56',
    'payer_status'           => 'verified',
    'custom'                 => '',
    'payment_gross'          => '',
    'txn_id'                 => '1SL733622J291505Y',
    'ipn_track_id'           => 'f213b31aadc45',
    'item_number2'           => 'store-provided-number2',
    'receiver_id'            => '5T8EHKLM3WZHU',
    'last_name'              => 'Smith',
    'mc_shipping'            => '0.00',
    'item_name2'             => 'Item name2',
    'payer_email'            => 'mr.buyer@test.com',
    'tax2'                   => '0.00',
    'transaction_subject'    => 'Shopping CartItem name1Item name2',
    'mc_gross_2'             => '2.00',
    'tax'                    => '0.00',
    'notify_version'         => '3.7',
    'mc_gross'               => '4.00',
    'mc_gross_1'             => '2.00',
    'mc_handling2'           => '0.00',
    'protection_eligibility' => 'Ineligible',
    'item_name1'             => 'Item name1',
    'mc_currency'            => 'BRL',
    'first_name'             => 'John'
);

{
    package FakeRequest;
    use Moo;
    sub param {
        my $self = shift;
        my $param_name = shift;
        return $param_name ? $params{$param_name} : (keys %params);
    }
}

{
    package FakeUserAgent;
    use Moo;
    sub post {
        $POSTED++;
        HTTP::Response->new(
            200,
            'OK',
            [
                'content-type' => 'application/x-www-form-urlencoded',
                'host'         => 'localhost'
            ],
            $IS_SUCCESS ? 'VERIFIED' : 'INVALID'
        )
    }
}

{
    $IS_SUCCESS = 1;
    $POSTED = 0;
    ok(my $ipn = Business::CPI::Gateway::PayPal::IPN->new(
        user_agent => FakeUserAgent->new,
        query      => FakeRequest->new,
    ), '$ipn object builds');

    isa_ok($ipn, 'Business::CPI::Gateway::PayPal::IPN', '$ipn');
    is($POSTED, 0, 'nothing has been posted yet');
    is($ipn->gateway_url, 'https://www.paypal.com/cgi-bin/webscr', 'gateway url is the default');
    ok($ipn->is_valid, 'the ipn is valid');
    is($POSTED, 1, 'something has been posted now');
    is_deeply($ipn->vars, \%params, 'the vars are expected');

    ok($ipn->is_valid, 'the ipn is still valid');
    is($POSTED, 1, "it didn't re-post");
}

{
    $IS_SUCCESS = 0;
    $POSTED = 0;
    ok(my $ipn = Business::CPI::Gateway::PayPal::IPN->new(
        user_agent => FakeUserAgent->new,
        query      => FakeRequest->new,
    ), '$ipn object builds');

    isa_ok($ipn, 'Business::CPI::Gateway::PayPal::IPN', '$ipn');
    is($POSTED, 0, 'nothing has been posted yet');
    is($ipn->gateway_url, 'https://www.paypal.com/cgi-bin/webscr', 'gateway url is the default');
    ok(!$ipn->is_valid, 'the ipn is not valid');
    is($POSTED, 1, 'something has been posted now');
    is_deeply($ipn->vars, \%params, 'the vars are expected');

    ok(!$ipn->is_valid, 'the ipn is still invalid');
    is($POSTED, 1, "it didn't re-post");
}

done_testing;

#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw(no_plan);

## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my @opts = ('default_Origin' => 'RECURRING' );

## grab test info from the storable^H^H yeah actually just DATA now

my $authed =
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID}
    ;

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3 if ! $authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'Supplied a MerchantID');
}

my %orig_content = (
    type        => 'CC',
    login       => $login,
    password    => $password,
    merchantid  =>  $merchantid,
    action      => 'Authorization Only', #'Normal Authorization',
    description => 'BLU*BusinessOnlinePayment',
#    card_number    => '4007000000027',
    card_number     => '4457010000000009',
    cvv2            => '123',
    expiration      => '11/16',
    amount          => '49.95',
    currency        => 'UsD',
    order_number    => '1234123412341234',
    name            => 'Tofu Beast',
    email           => 'ippay@weasellips.com',
    address         => '123 Anystreet',
    city            => 'Anywhere',
    state           => 'UT',
    zip             => '84058',
    country         => 'US',      # will be forced to USA
    customer_id     => 'tfb',
    company_phone   => '801.123-4567',
    phone           => '123.123-1234',
    invoice_number  => '1234',
    ip              =>  '127.0.0.1',
    ship_name       =>  'Tofu Beast, Co.',
    ship_address    =>  '123 Anystreet',
    ship_city       => 'Anywhere',
    ship_state      => 'UT',
    ship_zip        => '84058',
    ship_country    => 'US',      # will be forced to USA
    tax             => 10,
    products        =>  [
    {   description =>  'First Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  500,
        discount    =>  0,
        code        =>  'sku1',
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 500,
    },
    {   description =>  'Second Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  1500,
        discount    =>  0,
        code        =>  'sku2',
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 1500,
    }

    ],
);

my $token_result;
print '-'x70; print "REGISTER TOKEN TEST\n";
SKIP: {
    skip "No Test Account setup", if ! $authed;
    my %content = %orig_content;
    $content{'action'} = 'Tokenize';

    my $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction(1);
    $tx->content(%content);
    my $ret = $tx->submit;
    $token_result = $tx->result_code;
    skip "contact litle support to enable tokens",4 if defined $token_result && $token_result == 821;
    like( $tx->result_code,   qr/^(000|802)$/,   "result_code(): ".($tx->result_code||'').' - '.($tx->error_message||'') );
    skip "transaction did not process (check litle credentials)",3 if ! defined $tx->result_code && $tx->error_message =~ /System Error/;
    like( $tx->order_number, qr/^\w{5,19}/, "order_number(): ".($tx->order_number||'') );
    is( $tx->is_success,    1,    "is_success: 1" );
    like( $tx->card_token, qr/^\w{5,19}/, "card_token(): ".($tx->card_token||'') );
}

print '-'x70; print "AUTH CARD TOKEN TEST\n";
SKIP: {
    skip "No Test Account setup",4 if ! $authed;
    skip "first transaction did not process",4 if ! defined $token_result;
    skip "contact litle support to enable tokens",4 if $token_result == 821;
    my %content = %orig_content;
    $content{'action'} = 'Authorization Only';

    my $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction(1);
    $tx->content(%content);
    %content = %orig_content;
    $content{'action'} = 'Authorization Only';

    $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction(1);
    $tx->content(%content);
    my $ret = $tx->submit;
    is( $tx->is_success,    1,    "is_success: 1" );
    is( $tx->result_code,   '000',   "result_code(): ".($tx->result_code||'').' - '.($tx->error_message||'') );
    like( $tx->order_number, qr/^\w{5,19}/, "order_number(): ".($tx->order_number||'') );
    like( $tx->card_token, qr/^\w{5,19}/, "card_token(): ".($tx->card_token||'') );

    if ($tx->card_token) {
        $orig_content{'card_token'} = $tx->card_token;
        delete $orig_content{'card_number'};
    }
}

print '-'x70; print "AUTH TOKEN TOKEN TEST\n";
SKIP: {
    skip "No Test Account setup",4 if ! $authed;
    skip "contact litle support to enable tokens",4 if defined $token_result && $token_result == 821;
    skip "No Test Token Found",4 if ! $orig_content{'card_token'};
    my %content = %orig_content;
    $content{'action'} = 'Authorization Only';

    my $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction(1);
    $tx->content(%content);
    my $ret = $tx->submit;
    is( $tx->is_success,    1,    "is_success: 1" );
    is( $tx->result_code,   '000',   "result_code(): ".($tx->result_code||'').' - '.($tx->error_message||'') );
    like( $tx->order_number, qr/^\w{5,19}/, "order_number(): ".($tx->order_number||'') );
    like( $tx->card_token, qr/^\w{5,19}/, "card_token(): ".($tx->card_token||'') );
}

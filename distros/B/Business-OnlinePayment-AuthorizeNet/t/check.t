#!/usr/bin/perl -w

use Test::More skip_all => "Authorize.net test account won't do ACH";
require "t/lib/test_account.pl";

my($login, $password) = test_account_or_skip('ach');
plan tests => 2;

use_ok 'Business::OnlinePayment';

my $ctx = Business::OnlinePayment->new("AuthorizeNet");
$ctx->server('test.authorize.net');
$ctx->content(
    type           => 'CHECK',
    login          => $login,
    password       => $password,
    action         => 'Normal Authorization',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    account_name   => 'Tofu Beast',
    account_number => '12345',
    routing_code   => '111000025',  # BoA in Texas taken from Wikipedia
    bank_name      => 'First National Test Bank',
    account_type   => 'Checking',
    license_num    => '12345678',
    license_state  => 'OR',
    license_dob    => '1975-05-21',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

SKIP: {
    skip $ctx->error_message, 1 if $ctx->result_code == 18;
    ok( $ctx->is_success() ) || diag $ctx->error_message;
}

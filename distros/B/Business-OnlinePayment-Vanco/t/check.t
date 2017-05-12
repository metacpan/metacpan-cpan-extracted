#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password, %opt) = test_account_or_skip();
plan tests => 2;

use_ok 'Business::OnlinePayment';

my $ctx = Business::OnlinePayment->new("Vanco", %opt);
$ctx->content(
    type           => 'CHECK',
    login          => $login,
    password       => $password,
    action         => 'Normal Authorization',
    amount         => '49.95',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    account_number => '12345',
    routing_code   => '111000025',  # BoA in Texas taken from Wikipedia
    bank_name      => 'First National Test Bank',
    account_type   => 'Checking',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();
ok( $ctx->is_success() ) || diag $ctx->error_message;

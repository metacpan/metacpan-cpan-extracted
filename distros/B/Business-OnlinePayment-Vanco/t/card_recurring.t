#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password, %opts) = test_account_or_skip();
plan tests => 4;
  
use_ok 'Business::OnlinePayment';

my $tx = Business::OnlinePayment->new("Vanco", %opts);
$tx->content(
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Recurring Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '49.95',
    customer_id    => 'tofu',
    name           => 'Tofu Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => '5105105105105100',
    expiration     => expiration_date(),
    interval       => '1 month',
    start          => tomorrow(),
    periods        => '3',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

ok($tx->is_success()) or diag $tx->error_message;

my $subscription = $tx->order_number();
like($subscription, qr/^[0-9]{1,13}$/, "Get order number");

SKIP: {

  skip "No order number", 1 unless $subscription;

  $tx->content(
    login        => $login,
    password     => $password,
    action       => 'Cancel Recurring Authorization',
    subscription => $subscription,
  );
  $tx->test_transaction(1);
  $tx->submit();
  ok($tx->is_success()) or diag $tx->error_message;
}

#!/usr/bin/perl -w

use Test::More skip_all => 'Authorize.net test account throwing errors about duplicates';
require "t/lib/test_account.pl";

my($login, $password) = test_account_or_skip('arb');
plan tests => 5;
  
use_ok 'Business::OnlinePayment';

my $tx = Business::OnlinePayment->new("AuthorizeNet");
$tx->content(
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Recurring Authorization',
    description    => 'Business::OnlinePayment::ARB visa test',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => '4007000000027',
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

  skip "No order number", 2 unless $subscription;

  $tx->content(
    login        => $login,
    password     => $password,
    action       => 'Modify Recurring Authorization',
    subscription => $subscription,
    amount       => '19.95',
  );
  $tx->test_transaction(1);
  $tx->submit();
  ok($tx->is_success()) or diag $tx->error_message;

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

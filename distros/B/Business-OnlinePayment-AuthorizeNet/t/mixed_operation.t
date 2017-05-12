#!/usr/bin/perl -w

BEGIN { push @INC, "t/lib" };

use Test::More;

require "t/lib/test_account.pl";


my($arblogin, $arbpassword) = test_account_or_skip('arb');
my($aimlogin, $aimpassword) = test_account_or_skip();
plan tests => 9;
  
use_ok 'Business::OnlinePayment';
my $tx = Business::OnlinePayment->new("AuthorizeNet", 
                                      fraud_detect => '_Fake',
                                      fraud_detect_faked_result => '0',
                                      fraud_detect_faked_score => '2',
                                      maximum_fraud_score => '1',
                                     );
$tx->content(
    type           => 'VISA',
    login          => $arblogin,
    password       => $arbpassword,
    action         => 'Recurring Authorization',
    description    => 'Business::OnlinePayment::ARB mixed test',
    amount         => '1.05',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    card_number    => '4007000000027',
    expiration     => expiration_date(),
    interval       => '1 month',
    start          => tomorrow(),
    periods        => '6',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

ok(!$tx->is_success()) or diag "ARB Fraud detection unexpectedly did not fail.";

$tx->fraud_detect_faked_result(1);
$tx->submit();

ok(!$tx->is_success()) or diag "ARB Fraud detection unexpectedly did not deny.";

$tx->fraud_detect_faked_score(0);
$tx->submit();

ok($tx->is_success()) or diag $tx->error_message();

my $subscription = $tx->order_number();
like($subscription, qr/^[0-9]{1,13}$/, "Get order number");

SKIP: {

  skip "No order number", 1 unless $subscription;

  $tx->content(
    login        => $arblogin,
    password     => $arbpassword,
    action       => 'Cancel Recurring Authorization',
    subscription => $subscription,
  );
  $tx->test_transaction(1);
  $tx->submit();
  ok($tx->is_success()) or diag $tx->error_message;
}

$tx->server('test.authorize.net');
$tx->path('/gateway/transact.dll');
$tx->content(
    type           => 'VISA',
    login          => $aimlogin,
    password       => $aimpassword,
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::AIM mixed test',
    amount         => '1.06',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    card_number    => '4007000000027',
    expiration     => expiration_date(),
);
$tx->test_transaction(1); #test, don't really charge
$tx->fraud_detect_faked_result(0);
$tx->fraud_detect_faked_score(2);
$tx->submit();

ok(!$tx->is_success()) or diag "AIM Fraud detection unexpectedly did not fail.";

$tx->submit();
$tx->fraud_detect_faked_result(1);

ok(!$tx->is_success()) or diag "AIM Fraud detection unexpectedly did not deny.";

$tx->fraud_detect_faked_score(0);
$tx->submit();
ok($tx->is_success()) or diag $tx->error_message;


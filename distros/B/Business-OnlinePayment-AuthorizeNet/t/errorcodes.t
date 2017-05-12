#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password) = test_account_or_skip();
plan tests => 3;
  
use_ok 'Business::OnlinePayment';

my $tx = Business::OnlinePayment->new("AuthorizeNet");
$tx->server('test.authorize.net');
$tx->content(
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
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
    expiration     => 'BADFORMAT', #expiration_date(),
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

ok(!$tx->is_success);

ok($tx->error_message() =~ /The format of the date submitted was incorrect/ );

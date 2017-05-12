#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password) = test_account_or_skip();
plan tests => 4;

use_ok 'Business::OnlinePayment';

#avoid dup checking in case "make test" is run too close to the last
my $amount = sprintf('%.2f', rand(100));

my $tx = Business::OnlinePayment->new("AuthorizeNet");
$tx->server('test.authorize.net');
$tx->content(
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Authorization Only',
    description    => 'Business::OnlinePayment visa test',
    amount         => $amount,
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
);

# don't set test_transaction (using test server though, still a test)
# as per authorize.net:
#  "You need to be in Live Mode to get back a transaction ID"
#$tx->test_transaction(1); # test, dont really charge

$tx->submit();

ok($tx->is_success()) or diag $tx->error_message;

my $auth = $tx->authorization;

my $order_number = $tx->order_number;
like $order_number, qr/^\d+$/;

#warn "auth: $auth\n";
#warn "order_number: $order_number\n";

my $settle_tx = Business::OnlinePayment->new("AuthorizeNet");
$settle_tx->server('test.authorize.net');
$settle_tx->content(
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Post Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => $amount,
    invoice_number => '100100',
    authorization  => $auth,
    order_number   => $order_number,
    card_number    => '4007000000027',
    expiration     => expiration_date(),
);

#$settle_tx->test_transaction(1); # test, dont really charge
$settle_tx->submit();

ok($settle_tx->is_success()) || diag $settle_tx->error_message;

#!/usr/bin/perl -w

# B:OP eSelectPlus Canadian Pre-Auth & Capture
# Portions loosely adapted from B:OP AuthorizeNet via B:OP Exact

use Test::More;
plan tests => 5;

use_ok 'Business::OnlinePayment';

my $amount;
$amount = '1.00';
my $order_id;
$order_id = 'B:OP' . time;  # Caller generates order_id; cf. capture-us.t;

my $tx = new Business::OnlinePayment("eSelectPlus");
$tx->content(
    login          => 'moot',
    password       => 'moot',
    action         => 'Authorization Only',
    order_id       => $order_id,
#    description    => 'Business::OnlinePayment visa test',
    amount         => $amount,
    currency       => 'CAD',
#    name           => 'eSelectPlus Tester',
    card_number    => '4242424242424242',
    expiration     => '12/14',
);

$tx->test_transaction(1); # test, dont really charge

$tx->submit();

my $flag =
    ok($tx->is_success(), 'Pre-Auth') or diag $tx->error_message;

# note: long
# use Data::Dumper;
# diag(Dumper $tx);

my $auth = $tx->authorization;             # TransID
my $order_number = $tx->order_number;
#$order_id = $tx->order_id;
like $auth, qr/\d+/, 'authorization';
like $order_number, qr/\d+/, 'order number';
#ok $order_id, 'order ID';

#warn "auth: $auth\n";
#warn "order_number: $order_number\n";
SKIP: {
    skip 'Need pre-auth success, in order to test capture', 1
        unless $flag;

my $settle_tx = new Business::OnlinePayment("eSelectPlus");
$settle_tx->content(
    login          => 'moot',
    password       => 'moot',
    action         => 'Post Authorization',
#    description    => 'Business::OnlinePayment visa test',
    currency       => 'CAD',
    amount         => $amount,
    authorization  => $auth,
#    order_id       => $order_id,
    order_number   => $order_number,
#    name           => 'eSelectPlus Tester',
#    card_number    => '4242424242424242',
#    expiration     => '12/12',
);

$settle_tx->test_transaction(1); # test, dont really charge
$settle_tx->submit();

ok($settle_tx->is_success(), 'Capture') || diag $settle_tx->error_message;
}  # /skip or test

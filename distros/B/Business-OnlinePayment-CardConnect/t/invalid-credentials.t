#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Module::Runtime qw( use_module );

my $client = new_ok( use_module('Business::OnlinePayment'), ['CardConnect'] );

my $data = {
 login          => 123,
 password       => 123,
 merchantid     => 123,
 invoice_number => 44544,
 type           => 'CC',
 action         => 'Authorization Only',
 description    => 'Business::OnlinePayment visa test',
 amount         => '90.00',
 first_name     => 'Tofu',
 last_name      => 'Beast',
 address        => '123 Anystreet',
 city           => 'Anywhere',
 state          => 'UT',
 zip            => '84058',
 country        => 'US',
 email          => 'tofu@beast.org',
 card_number    => '4111111111111111',
 expiration     => '12/25',
 cvv2           => 321, };

$client->content(%$data);
$client->test_transaction(1); # doesn't really do anything in CardConnect since they don't have a sandbox

my $success = $client->submit();

ok !$client->is_success(), 'Transaction failed';

done_testing();

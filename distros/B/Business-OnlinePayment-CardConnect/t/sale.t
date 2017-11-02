#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Module::Runtime qw( use_module );

my $username = $ENV{PERL_CARDCONNECT_USERNAME};
my $password = $ENV{PERL_CARDCONNECT_PASSWORD};
my $mid      = $ENV{PERL_CARDCONNECT_MID};

plan skip_all => 'No credentials set in the environment.'
  . ' Set PERL_CARDCONNECT_MID, PERL_CARDCONNECT_USERNAME and '
  . 'PERL_CARDCONNECT_PASSWORD to run this test.'
  unless ( $username && $password && $mid );

my $client = new_ok( use_module('Business::OnlinePayment'), ['CardConnect'] );

my $data = {
 login          => $username,
 password       => $password,
 merchantid     => $mid,
 invoice_number => 44544,
 type           => 'CC',
 action         => 'Normal Authorization',
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

ok $client->is_success(), 'Transaction successful'
  or do { diag $client->error_message(); diag 'auth failed cannot continue'; done_testing(); exit; };

ok $success->{'batchid'}, 'Transaction capture data found';
done_testing();

#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Module::Runtime qw( use_module );
use Test::More;
use Try::Tiny;

my $username = $ENV{PERL_BUSINESS_CYBERSOURCE_USERNAME};
my $password = $ENV{PERL_BUSINESS_CYBERSOURCE_PASSWORD};

plan skip_all => 'No credentials set in the environment.'
  . ' Set PERL_BUSINESS_CYBERSOURCE_USERNAME and '
  . 'PERL_BUSINESS_CYBERSOURCE_PASSWORD to run this test.'
  unless ( $username && $password );

my $client = new_ok( use_module('Business::OnlinePayment'), ['CyberSource'] );

my $data = {
 login          => $username,
 password       => $password,
 invoice_number => 44544,
 type           => 'CC',
 action         => 'Authorization Only',
 description    => 'Business::OnlinePayment visa test',
 amount         => 3000.49,
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
 cvv2           => 1111, };

$client->test_transaction(1);
$client->content(%$data);

eval { $client->submit() };

like $@, qr/General\ system\ failure/x, 'Throws exceptions on transmission error';

my $e = {};

try {
 $client->submit();
}
catch {
 $e = shift;
};

isa_ok $e, 'Business::CyberSource::Response::Exception', 'BC Response Exception';

done_testing;

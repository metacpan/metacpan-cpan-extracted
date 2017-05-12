#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Module::Runtime qw( use_module );

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
 amount         => '9000',
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

$client->content(%$data);
$client->test_transaction(1);    # test, dont really charge

my $success = $client->submit();

if ($success) {
 my $options = {
  login          => $data->{login},
  password       => $data->{password},
  invoice_number => $data->{invoice_number},
  action         => 'Post Authorization',
  type           => $data->{type},
  amount         => $data->{amount},
  po_number      => $client->order_number(), };

 $client->content(%$options);

 $success = $client->submit();

 ok $client->is_success(), 'transaction successful'
   or diag $client->error_message();

 is $client->is_success(), $success, 'Success matches';

 like $client->order_number(), qr/^\w+$/x, 'Order number matches';

 like $client->response_code(), qr/^\w+$/x, 'Response code is 200';
 is ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
 like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
 is $client->login(),    $username, 'Login matches';
 is $client->password(), $password, 'Password matches';
 is $client->test_transaction(), 1, 'Test transaction matches';

 is $client->server(), 'ics2wstest.ic3.com',                'Server matches';
 is $client->port(),   443,                                 'Port matches';
 is $client->path(),   'commerce/1.x/transactionProcessor', 'Path matches';

 $data->{first_name} = 'test';
 $data->{last_name}  = 'user';
 $data->{email}      = 'test.user@example.com';

 $client->content(%$data);

 $success = $client->submit();

 ok $success, 'Capture was successful'
   or diag $client->error_message();
}
else {
 BAIL_OUT "Could not authorize successfully!\n" . $client->error_message();
}

done_testing;

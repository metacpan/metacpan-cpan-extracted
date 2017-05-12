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
 type           => 'CC',
 action         => 'Authorization Only',
 description    => 'Business::OnlinePayment visa test',
 amount         => '9000',
 invoice_number => '100100',
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

ok $client->is_success(), 'transaction successful'
  or diag $client->error_message();

is $client->is_success(), $success, 'Success matches';
like $client->authorization(), qr/^\w+$/, 'Authorization is a string';
like $client->order_number(),  qr/^\w+$/, 'Order number is a string';
ok !defined( $client->card_token() ),           'Card token is not defined';
ok !defined( $client->fraud_score() ),          'Fraud score is not defined';
ok !defined( $client->fraud_transaction_id() ), 'Fraud transaction id is not defined';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200';
is ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
like $client->result_code(),   qr/^\w+$/,  'Result code is a string';
is $client->avs_code(),        'Y',        'AVS code is a string';
is $client->cvv2_response(),   'M',        'CVV2 code is a string';
is $client->transaction_type(), $data->{type}, 'Type matches';
is $client->login(),    $username, 'Login matches';
is $client->password(), $password, 'Password matches';
is $client->test_transaction(), 1,                                   'Test transaction matches';
is $client->require_avs(),      0,                                   'Require AVS matches';
is $client->server(),           'ics2wstest.ic3.com',                'Server matches';
is $client->port(),             443,                                 'Port matches';
is $client->path(),             'commerce/1.x/transactionProcessor', 'Path matches';

my %reversal_data = (
 login          => $username,
 password       => $password,
 type           => 'CC',
 action         => 'Void',
 amount         => $data->{amount},
 invoice_number => $data->{invoice_number},
 po_number      => $client->order_number, );

$client->content(%reversal_data);
$client->test_transaction(1);

$client->submit;

ok $client->is_success, 'transaction successful'
  or diag $client->error_message;

like $client->response_code, qr/^\w+$/x, 'response code is 200';
like $client->order_number,  qr/^\w+$/,  'order number is a string';

done_testing;

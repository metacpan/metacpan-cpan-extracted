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

ok $client->is_success(), 'transaction successful'
  or diag $client->error_message();

is $client->is_success(), $success, 'Success matches';
like $client->authorization(), qr/^\w+$/, 'Authorization is a string';
like $client->order_number(),  qr/^\w+$/, 'Order number is a string';
ok !defined( $client->card_token() ),           'Card token is not defined';
ok !defined( $client->fraud_score() ),          'Fraud score is not defined';
ok !defined( $client->fraud_transaction_id() ), 'Fraud transaction id is not defined';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200';
diag $client->response_code();
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

$data->{invoice_number} += 100;
$data->{amount} = 5005.00;

$client->content(%$data);

$success = $client->submit();

ok $success, 'Successful transaction';
is $client->response_code(), 200, 'response_code matches';
is $client->avs_code(),      'N', 'avs_code matches';
is $client->result_code(),   100, 'result_code matches';

$data->{invoice_number} += 100;

$client->require_avs(1);
$client->content(%$data);

$success = $client->submit();

ok !$success, 'Transaction failed';
is $client->response_code(), 200, 'response_code matches';
is $client->avs_code(),      'N', 'avs_code matches';
is $client->result_code(),   200, 'result_code matches';
is $client->error_message(),
  'The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the Address Verification Service (AVS) check',
  'error_message matches';

$data->{invoice_number} += 100;
$data->{amount} = 3000.04;

$client->require_avs(0);
$client->content(%$data);

$success = $client->submit();

ok !$success, 'Transaction failed';
is $client->response_code(), 200, 'response_code matches';
is $client->avs_code(),      'Y', 'avs_code matches';
is $client->result_code(),   201, 'result_code matches';
is $client->error_message(),
  'The issuing bank has questions about the request. You do not receive an authorization code programmatically, but you might receive one verbally by calling the processor',
  'error_message matches';

$data->{invoice_number} += 100;
$data->{amount} = 3000.37;

$client->content(%$data);

$success = $client->submit();

ok !$success, 'Transaction failed';
is $client->response_code(), 200, 'response_code matches';
is $client->avs_code(),      'Y', 'avs_code matches';
is $client->result_code(),   202, 'result_code matches';
is $client->error_message(),
  'Expired card. You might also receive this if the expiration date you provided does not match the date the issuing bank has on file',
  'error_message matches';

done_testing;

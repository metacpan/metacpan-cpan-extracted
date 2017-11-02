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

ok $client->is_success(), 'Transaction successful'
  or do { diag $client->error_message(); diag 'auth failed cannot continue'; done_testing(); exit; };

is $client->is_success(), $success, 'Success matches';
like $client->authorization(), qr/^\w+$/, 'Authorization is a string';
like $client->order_number(),  qr/^\w+$/, 'Order number is a string';
ok $client->card_token(),      'Card token is defined';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200' or diag $client->response_code();
is ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
like $client->result_code(),   qr/^\w+$/,  'Result code is a string';
like $client->avs_code(),        qr/^\w+$/,        'AVS code is a string';
like $client->cvv2_response(),   qr/^\w+$/,        'CVV2 code is a string';
is $client->transaction_type(), $data->{type}, 'Type matches';
is $client->login(),    $username, 'Login matches';
is $client->password(), $password, 'Password matches';
is $client->test_transaction(), 1,                                   'Test transaction matches';
is $client->require_avs(),      0,                                   'Require AVS matches';
is $client->server(),           'fts.cardconnect.com',               'Server matches';
is $client->port(),             6443,                                'Port matches';
is $client->path(),             '/cardconnect/rest/auth',            'Path matches';




my $void_data = {
    action       => 'Auth Reversal',
    order_number => $client->order_number,
};
$void_data->{$_} = $data->{$_} foreach qw(login password merchantid amount);
my $void_client = new_ok( use_module('Business::OnlinePayment'), ['CardConnect'] );
$void_client->content(%$void_data);
$void_client->test_transaction(1); # doesn't really do anything in CardConnect since they don't have a sandbox
$success = $void_client->submit();

ok $void_client->is_success(), 'Auth Reversal successful'
  or do { diag $void_client->error_message(); diag 'viod failed cannot continue'; done_testing(); exit; };

is $void_client->is_success(), $success, 'Auth Reversal success matches';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200' or diag $client->response_code();
like $client->order_number(),  qr/^\w+$/, 'Order number is a string';

done_testing();

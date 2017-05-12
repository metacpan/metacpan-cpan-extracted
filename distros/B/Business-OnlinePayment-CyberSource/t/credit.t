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

# Stand-alone credit
my $data = {
 login          => $username,
 password       => $password,
 invoice_number => 44544,
 type           => 'CC',
 action         => 'Credit',
 description    => 'Business::OnlinePayment credit test',
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

ok $client->is_success(), 'Credit was successful'
  or diag $client->error_message();

is $client->is_success(), $success, 'Success maches';
like $client->order_number(),  qr/^\w+$/x, '';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200';
is ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
is $client->transaction_type(), $data->{type}, 'Type matches';
is $client->login(),    $username, 'Login matches';
is $client->password(), $password, 'Password matches';
is $client->test_transaction(), 1,                                   'Test transaction matches';
is $client->server(),           'ics2wstest.ic3.com',                'Server matches';
is $client->port(),             443,                                 'Port matches';
is $client->path(),             'commerce/1.x/transactionProcessor', 'Path matches';

# Follow-on credit
$data->{action} = 'Normal Authorization';

$client->content(%$data);

$success = $client->submit();

my $options = {
 login          => $data->{login},
 password       => $data->{password},
 invoice_number => $data->{invoice_number},
 type           => $data->{type},
 action         => 'Credit',
 description    => $data->{description},
 amount         => $data->{amount},
 card_number    => $data->{card_number},
 expiration     => $data->{expiration},
 cvv2           => $data->{cvv2},
 po_number      => $client->order_number(), };

$client->content(%$options);

$success = $client->submit();

ok $client->is_success(), 'Credit was successful'
  or diag $client->error_message();

is $client->is_success(), $success, 'Success matches';
like $client->order_number(),  qr/^\w+$/x, 'Order number is a string';
like $client->response_code(), qr/^\w+$/x, 'Response code is 200';
is ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
is $client->transaction_type(), $data->{type}, 'Type matches';
is $client->login(),    $username, 'Login matches';
is $client->password(), $password, 'Password matches';
is $client->test_transaction(), 1,                                   'Test transaction matches';
is $client->server(),           'ics2wstest.ic3.com',                'Server matches';
is $client->port(),             443,                                 'Port matches';
is $client->path(),             'commerce/1.x/transactionProcessor', 'Path matches';

# Misuse case: bad reference_code
$options->{po_number} .= 500;
$options->{amount} += 100;

$client->content(%$options);

$success = try {
 $client->submit();
}
catch {
 my ($e) = @_;

 isa_ok $e, 'Business::CyberSource::Response::Exception';
 like "$e", qr/invalidField/x, 'Exception message matches';
};

done_testing;

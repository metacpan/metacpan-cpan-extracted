#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Module::Runtime qw( use_module );
use Time::HiRes;

my $username = $ENV{PERL_BUSINESS_DLOCAL_USERNAME} || 'mocked';
my $password = $ENV{PERL_BUSINESS_DLOCAL_PASSWORD} || 'mocked';
my $secret   = $ENV{PERL_BUSINESS_DLOCAL_SECRET}   || 'mocked';
my $reports_username   = $ENV{PERL_BUSINESS_DLOCAL_REPORTS_USERNAME}   || 'mocked';
my $reports_key   = $ENV{PERL_BUSINESS_DLOCAL_REPORTS_KEY}   || 'mocked';

if ($username eq 'mocked' || $reports_username eq 'mocked') {
    diag '';
    diag '';
    diag '';
    diag 'All tests are run using MOCKED return values.';
    diag 'If you wish to run REAL tests then add these ENV variables.';
    diag '';
    diag 'export PERL_BUSINESS_DLOCAL_USERNAME=your_test_user';
    diag 'export PERL_BUSINESS_DLOCAL_PASSWORD=your_test_password';
    diag 'export PERL_BUSINESS_DLOCAL_SECRET=your_test_secret';
    diag 'export PERL_BUSINESS_DLOCAL_REPORTS_USERNAME=your_reports_user';
    diag 'export PERL_BUSINESS_DLOCAL_REPORTS_KEY=your_reports_key';
    diag '';
    diag '';
}

if ( $username ne 'mocked' && $password ne 'mocked') {
    plan tests => 3;
} else {
    plan skip_all => 'No credentials set in the environment.'
      . ' Set PERL_BUSINESS_DLOCAL_USERNAME and '
      . ' PERL_BUSINESS_DLOCAL_SECRET and '
      . 'PERL_BUSINESS_DLOCAL_PASSWORD to run this test.'
}

my $client = new_ok( use_module('Business::OnlinePayment'), ['DLocal'] );
$client->test_transaction(1);    # test, dont really charge

my $data = {
 login          => $username,
 password       => $password,
 password2      => $secret,
 reports_login  => $reports_username,
 reports_key    => $reports_key,
 ##### action         => 'fetchByMerchantTransactionId',
 description    => 'Business::OnlinePayment visa test',

 division_number     => '1',
 type                => 'CC',
 amount              => '90.00',
 customer_number     => '123',
 subscription_number => 'TEST-'.Time::HiRes::time(),
 invoice_number      => 'TEST-'.Time::HiRes::time(),
 authorization       => '123456',
 timestamp           => '2012-09-11T22:34:32.265Z',
 first_name          => 'Tofu',
 last_name           => 'Beast',
 address             => '123 Anystreet',
 city                => 'Anywhere',
 state               => 'UT',
 zip                 => '84058',
 country             => 'BR',
 currency            => 'USD',
 email               => 'bop@example.com',
 card_number         => '4556993263529121',
 cvv2                => '554',
 cpf => '00003456789',
 expiration          => '06/19',
 vindicia_nvp        => {
     custom_test => 'BOP:DLocal unit test',
 }
};

subtest 'CurrencyExchange' => sub {
    plan tests => 3;
    local $data->{'action'} = 'CurrencyExchange';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'currencyexchange',
        login => 'mocked',
        resp => '3.21',
    } if $data->{'reports_login'} eq 'mocked';
    my $ret = eval { $client->submit() };
    ok($client->is_success, 'Transaction is_success');
    cmp_ok($client->order_number, '>', 0, 'Transaction order_number found');
    ok($ret && $ret > 0, 'Found the expected result');
} or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;

subtest 'CurrencyExchange bad country' => sub {
    plan tests => 2;
    local $data->{'action'} = 'CurrencyExchange';
    local $data->{'country'} = 'ZZ'; # bad country code on purpose
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'currencyexchange',
        login => 'mocked',
        resp => '0',
    } if $data->{'reports_login'} eq 'mocked';
    my $ret = eval { $client->submit() };
    ok(!$client->is_success, 'Transaction is_success');
    ok(! defined $client->order_number, 'Transaction order_number was undef as expected');
} or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;

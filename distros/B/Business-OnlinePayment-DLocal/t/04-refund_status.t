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

if ($username eq 'mocked') {
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
    plan tests => 6;
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

SKIP: { # Save
    subtest 'Tokenize' => sub {
        plan tests => 2;
        local $data->{'action'} = 'Tokenize';
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'tokenize',
            login => 'mocked',
            resp => '{"status":"OK","desc":"authorized","control":"C265401C3B048F429B7523692F0551CD2E7C4E2109680B86BE598E11C5D7B979","cc_token":"1efcd735c820a542e0e0de57b7900d4b"}',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        ok($client->is_success, 'Transaction is_success');
        ok($client->card_token, 'Transaction card_token found');
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
    $data->{'card_token'} = $client->card_token; # all tests below will use this
}

SKIP: { # Sale with token
    skip 'No card_token was found', 1 unless $data->{'card_token'};
    subtest 'Normal Authorization with card_token' => sub {
        plan tests => 3;
        local $data->{'action'} = 'Normal Authorization';
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'normal authorization',
            login => 'mocked',
            resp => '{"status":"OK","desc":"approved","control":"99A0A20207BFE0C74C233B4D68D552CF07F3D622DB390A335E48C7F6044B525D","result":"9","x_invoice":"TEST-1485554128.04736","x_iduser":"","x_description":"Business::OnlinePayment visa test","x_document":"93064512","x_amount":"90.00","x_currency":"USD","cc_token":"","x_amount_paid":"305.36","cc_descriptor":"Bluehost"}',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        ok($client->is_success, 'Transaction is_success');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction result exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected result');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
    $data->{'order_number'} = $client->order_number;
}

SKIP: { # Refund
    skip 'No order_number was found', 1 unless $data->{'order_number'};
    subtest 'Refund' => sub {
        plan tests => 3;
        local $data->{'action'} = 'Credit';
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'credit',
            login => 'mocked',
            resp => '{"status":"OK","desc":"refunded","control":"249EC6C29591767029C6CA6D8B6424C3ABA6AC23F79E6E4B4381B949A6C137AA","result":"1","x_invoice":"TEST-1485554128.04736","x_document":"93064512","x_amount":"90.00","x_currency":"USD","x_refund":"15648","x_amount_refunded":"305.36"}',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        ok($client->is_success, 'Transaction is_success');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction result exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '1', 'Found the expected result');
        };
        $data->{'order_number'} = $ret->{'x_refund'};
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Refund Status
    skip 'No order_number was found', 1 unless $data->{'order_number'};
    subtest 'RefundStatus' => sub {
        plan tests => 3;
        local $data->{'action'} = 'RefundStatus';
        local $data->{'x_'} = 'RefundStatus';
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'refundstatus',
            login => 'mocked',
            resp => '{"result":"1","x_document":"93064512","x_invoice":"TEST-1485554128.04736"}',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        ok($client->is_success, 'Transaction is_success');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction result exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '1', 'Found the expected result');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Refund Status Fail
    skip 'No order_number was found', 1 unless $data->{'order_number'};
    subtest 'RefundStatus bad x_refund value' => sub {
        plan tests => 3;
        local $data->{'action'} = 'RefundStatus';
        local $data->{'x_'} = 'RefundStatus';
        $data->{'order_number'} = 'bad id';
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'refundstatus',
            login => 'mocked',
            resp => '{"status":"ERROR","desc":"Invalid refund"}',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        ok(!$client->is_success, 'Transaction is_success');
        ok(!$client->order_number, 'Transaction order_number found');
        isa_ok($ret,'HASH');
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

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
};


SKIP: { # Auth/capture no token
    subtest 'Authorization Only, with full card - VI' => sub {
        plan tests => 4;
        local $data->{'action'} = 'Authorization Only';
        local $data->{'invoice_number'} = $data->{'invoice_number'}.'-auth-no-token';
        delete local $data->{'card_token'};
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'billTransactions',
            login => 'mocked',
            resp => 'ok_duplicate',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        SKIP: {
            skip 'Auth/Capture API is not enabled', 4 if $ret->{'error_code'}//'' eq '403';
            ok($client->is_success, 'Transaction is_success');
            ok($client->order_number, 'Transaction order_number found');
            subtest 'A transaction result exists, as expected' => sub {
                plan tests => 2;
                isa_ok($ret,'HASH');
                return unless ref $ret eq 'HASH';
                cmp_ok($ret->{'result'}, 'eq', '11', 'Found the expected result');
            };

            skip 'Cannot capture without an auth', 1 unless $client->is_success && $client->order_number;
            local $data->{'order_number'} = $client->order_number;
            subtest 'Capture' => sub {
                plan tests => 3;
                local $data->{'action'} = 'post authorization';
                local $data->{'order_number'} = $client->order_number();
                delete local $data->{'card_token'};
                $client->content(%$data);
                push @{$client->{'mocked'}}, {
                    action => 'billTransactions',
                    login => 'mocked',
                    resp => 'ok_duplicate',
                } if $data->{'login'} eq 'mocked';
                my $ret = $client->submit();
                ok($client->is_success, 'Transaction is_success');
                ok($client->order_number, 'Transaction order_number found');
                subtest 'A transaction error exists, as expected' => sub {
                    plan tests => 2;
                    isa_ok($ret,'HASH');
                    return unless ref $ret eq 'HASH';
                    cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected result');
                };
            } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
        }
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

$data->{'card_number'} = '5031433215406351';
$data->{'cvv2'} = '153';
$data->{'expiration'} = '09/20';

SKIP: { # Auth/capture no token
    subtest 'Authorization Only, with full card - MC ' => sub {
        plan tests => 4;
        local $data->{'action'} = 'Authorization Only';
        local $data->{'invoice_number'} = $data->{'invoice_number'}.'-auth-no-token';
        delete local $data->{'card_token'};
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'billTransactions',
            login => 'mocked',
            resp => 'ok_duplicate',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        SKIP: {
            skip 'Auth/Capture API is not enabled', 4 if $ret->{'error_code'}//'' eq '403';
            ok($client->is_success, 'Transaction is_success');
            ok($client->order_number, 'Transaction order_number found');
            subtest 'A transaction result exists, as expected' => sub {
                plan tests => 2;
                isa_ok($ret,'HASH');
                return unless ref $ret eq 'HASH';
                cmp_ok($ret->{'result'}, 'eq', '11', 'Found the expected result');
            };

            skip 'Cannot capture without an auth', 1 unless $client->is_success && $client->order_number;
            local $data->{'order_number'} = $client->order_number;
            subtest 'Capture' => sub {
                plan tests => 3;
                local $data->{'action'} = 'post authorization';
                local $data->{'order_number'} = $client->order_number();
                delete local $data->{'card_token'};
                $client->content(%$data);
                push @{$client->{'mocked'}}, {
                    action => 'billTransactions',
                    login => 'mocked',
                    resp => 'ok_duplicate',
                } if $data->{'login'} eq 'mocked';
                my $ret = $client->submit();
                ok($client->is_success, 'Transaction is_success');
                ok($client->order_number, 'Transaction order_number found');
                subtest 'A transaction error exists, as expected' => sub {
                    plan tests => 2;
                    isa_ok($ret,'HASH');
                    return unless ref $ret eq 'HASH';
                    cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected result');
                };
            } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
        }
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

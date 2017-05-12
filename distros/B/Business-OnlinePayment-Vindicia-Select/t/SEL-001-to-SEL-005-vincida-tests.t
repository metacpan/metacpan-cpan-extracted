#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;
use Module::Runtime qw( use_module );
use Time::HiRes;

my $username = $ENV{PERL_BUSINESS_VINDICIA_USERNAME} || 'mocked';
my $password = $ENV{PERL_BUSINESS_VINDICIA_PASSWORD} || 'mocked';

if ($username eq 'mocked') {
    diag '';
    diag '';
    diag '';
    diag 'All tests are run using MOCKED return values.';
    diag 'If you wish to run REAL tests then add these ENV variables.';
    diag '';
    diag 'export PERL_BUSINESS_VINDICIA_USERNAME=your_test_user';
    diag 'export PERL_BUSINESS_VINDICIA_PASSWORD=your_test_password';
    diag '';
    diag '';
}

plan skip_all => 'No credentials set in the environment.'
  . ' Set PERL_BUSINESS_VINDICIA_USERNAME and '
  . 'PERL_BUSINESS_VINDICIA_PASSWORD to run this test.'
  unless ( $username && $password );

my $client = new_ok( use_module('Business::OnlinePayment'), ['Vindicia::Select'] );
$client->test_transaction(1);    # test, dont really charge

my $data = {
 login          => $username,
 password       => $password,
 ##### action         => 'fetchByMerchantTransactionId',
 description    => 'Business::OnlinePayment visa test',

 division_number     => '1',
 type                => 'CC',
 amount              => '9000',
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
 country             => 'US',
 email               => 'tofu@beast.org',
 card_number         => '4111111111111111',
 card_token          => '1',
 expiration          => '12/25',
 vindicia_nvp        => {
     custom_test => 'BOP:Vindica:Select unit test',
 }
};
my $trans;
foreach my $n ( 1 .. 3, 3 ) { # we do "3" twice to test what an error message looks like
    my %new_data = %$data;
    $new_data{'subscription_number'} .= "-$n";
    $new_data{'invoice_number'} .= "-$n";
    $new_data{'amount'} .= $n;
    push @$trans, \%new_data;
}

SKIP: { # SEL-001
    local $data->{'action'} = 'billTransactions';
    local $data->{'transactions'} = $trans;
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'SEL-001 billTransactions soapId: '.($client->order_number // 'NONE') => sub {
        plan tests => 3;
        ok($client->is_success, 'billTransactions successful');
        ok($client->order_number, 'billTransactions lookup soapId recorded');
        subtest 'A transaction error exist, as expected' => sub {
            plan tests => 3;
            isa_ok($ret->{'response'},'ARRAY');
            return unless ref $ret->{'response'} eq 'ARRAY';
            cmp_ok(scalar @{$ret->{'response'}}, '==', 1, 'Found the expected number of errors');
            cmp_ok($ret->{'response'}->[0]->{'code'}, '==', '400', 'Found the expected error result');
        };
    } or diag explain $client->server_request,$client->server_response;
}

SKIP: {
    my $data2 = {
        login           => $username,
        password        => $password,
        action          => 'fetchBillingResults',
        start_timestamp => '2016-10-11T20:34:32.265Z',
        end_timestamp   => '2016-10-21T22:34:32.265Z',
        page            => 0,
        page_size       => 2,
    };
    push @{$client->{'mocked'}}, {
        action => 'fetchBillingResults',
        login => 'mocked',
        resp => 'ok',
    } if $data->{'login'} eq 'mocked';
    $client->content(%$data2);
    my $ret = $client->submit();
    subtest 'SEL-002 (a) fetchBillingResults soapId: '.($client->order_number // 'NONE') => sub {
        plan tests => 5;
        ok($client->is_success, 'fetchBillingResults successful');
        ok($client->order_number, 'fetchBillingResults lookup soapId recorded');
        SKIP: {
            skip "No transactions found", 3 unless exists $ret->{'transactions'}; # don't fail, it's very possible they never did a transaction during this time
            isa_ok($ret->{'transactions'},'ARRAY',"Transactions array found");
            skip "Not an array", 2 unless exists $ret->{'transactions'}; # don't fail, it's very possible they never did a transaction during this time
            isa_ok($ret->{'transactions'}->[0],'HASH',"Transaction hash found");
            skip "Not a hash", 1 unless exists $ret->{'transactions'}; # don't fail, it's very possible they never did a transaction during this time
            ok($ret->{'transactions'}->[0]->{'selectTransactionId'},"Transaction contained a selectTransactionId");
        }
    } or diag explain $client->server_request,$client->server_response,$ret;
}

SKIP: {
    local $data->{'action'} = 'fetchByMerchantTransactionId';
    push @{$client->{'mocked'}}, {
        action => 'fetchByMerchantTransactionId',
        login => 'mocked',
        resp => 'ok',
    } if $data->{'login'} eq 'mocked';
    $client->content(%$data);
    my $ret = $client->submit();
    subtest 'SEL-002 (b) fetchByMerchantTransactionId soapId: '.($client->order_number // 'NONE') => sub {
        plan tests => 9;
        ok($client->is_success, 'fetchByMerchantTransactionId successful');
        ok($client->order_number, 'fetchByMerchantTransactionId lookup soapId recorded');
        ok($ret->{'transaction'}->{$_},"Transaction has a $_") foreach qw{customerId subscriptionId status merchantTransactionId amount currency authCode};
    } or diag explain $client->server_request,$client->server_response,$ret;
}

SKIP: {
    local $data->{'action'} = 'refundTransactions';
    push @{$client->{'mocked'}}, {
        action => 'refundTransactions',
        login => 'mocked',
        resp => 'ok',
    } if $data->{'login'} eq 'mocked';
    $client->content(%$data);
    my $ret = $client->submit();
    subtest 'SEL-003 refundTransactions soapId: '.($client->order_number // 'NONE') => sub {
        plan tests => 3;
        ok($client->is_success, 'refundTransactions successful');
        ok($client->order_number, 'refundTransactions lookup soapId recorded');
        ok(!$ret->{'response'},'refundTransactions lookup did not return any errors (sadly this test is terrible because Vindicia does not do a good job on what it considers an "error")');
    } or diag explain $client->server_request,$client->server_response,$ret;
}

SKIP: { skip 'SEL-004 is not needed, if someone requests it we can add it later', 1; }
SKIP: { skip 'SEL-005 is functionally the same as SEL-003 from a unit test perspective', 1; }

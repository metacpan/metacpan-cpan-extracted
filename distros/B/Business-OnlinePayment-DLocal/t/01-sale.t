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
    plan tests => 20;
} else {
    plan skip_all => 'No credentials set in the environment.'
      . ' Set PERL_BUSINESS_DLOCAL_USERNAME and '
      . ' PERL_BUSINESS_DLOCAL_SECRET and '
      . 'PERL_BUSINESS_DLOCAL_PASSWORD to run this test.'
}

my $client = new_ok( use_module('Business::OnlinePayment'), ['DLocal'] );
$client->test_transaction(1);    # test, dont really charge

my @test_cards = (
    '6363687851866592',
    '6062823125988953',
    #'5300323635297148',
    '3696656326587732', # DC
    '4312522698854138', # VI
    '3432524265896994', # AMEX
    '5578390741038760', # MC

    '5078601870000123', # aura
    '5895626746595650', # naranja
    '5200533989557118', # nativa
    #'6034883265619896', # tarjeta
    #'6034932528973614', # cencosud
    #'6271701225979642', # cabal
    '5011054488597827', # Argencard
);


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
 first_name          => 'Bop',
 last_name           => 'Testing',
 address             => '123',
 city                => 'Santa Isabel',
 state               => 'RJ',
 zip                 => '0750000',
 country             => 'BR',
 currency            => 'USD',
 email               => 'testing2@astropaycard.com',
 card_number         => $test_cards[0],
 cvv2                => '554',
 cpf                 => '00003456789',
 expiration          => '06/19',
 device_id           => '54hj4h5jh46hasjd',
};

SKIP: { # Sale no token (should decline)
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'invoice_number'} = $data->{'invoice_number'}.'-no-token';
    local $data->{'first_name'} = 'FUND';
    local $data->{'last_name'} = '';
    delete local $data->{'card_token'};
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization, with full card - FUND RESPONSE' => sub {
        plan tests => 3;
        ok(!$client->is_success, 'Transaction is_success failed as expected');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction error exists, as expected' => sub {
            plan tests => 3;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '8', 'Found the expected error result');
            cmp_ok($ret->{'desc'}, 'eq', 'cc_rejected_insufficient_amount', 'Found the expected error description');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}
SKIP: { # Sale no token (should decline)
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'invoice_number'} = $data->{'invoice_number'}.'-no-token';
    local $data->{'first_name'} = 'CALL';
    local $data->{'last_name'} = '';
    delete local $data->{'card_token'};
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization, with full card - CALL RESPONSE' => sub {
        plan tests => 3;
        ok(!$client->is_success, 'Transaction is_success failed as expected');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction error exists, as expected' => sub {
            plan tests => 3;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '8', 'Found the expected error result');
            cmp_ok($ret->{'desc'}, 'eq', 'cc_rejected_call_for_authorize', 'Found the expected error description');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Sale no token (should decline)
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'invoice_number'} = $data->{'invoice_number'}.'-no-token';
    local $data->{'first_name'} = 'PEND';
    local $data->{'last_name'} = '';
    delete local $data->{'card_token'};
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization, with full card - PENDING RESULT' => sub {
        plan tests => 3;
        ok(!$client->is_success, 'Transaction is_success failed as expected');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction error exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '7', 'Found the expected error result');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Sale no token (should decline)
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'invoice_number'} = $data->{'invoice_number'}.'-no-token';
    local $data->{'first_name'} = 'REJE';
    local $data->{'last_name'} = '';
    delete local $data->{'card_token'};
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization, with full card - REJECTED RESULT' => sub {
        plan tests => 3;
        ok(!$client->is_success, 'Transaction is_success failed as expected');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction error exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '8', 'Found the expected error result');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Sale no token
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'invoice_number'} = $data->{'invoice_number'}.'-no-token';
    delete local $data->{'card_token'};
    foreach my $card (@test_cards){
        local $data->{'card_number'} = $card;
        $client->content(%$data);
        push @{$client->{'mocked'}}, {
            action => 'billTransactions',
            login => 'mocked',
            resp => 'ok_duplicate',
        } if $data->{'login'} eq 'mocked';
        my $ret = $client->submit();
        subtest 'Normal Authorization, with full card' => sub {
            plan tests => 3;
            ok($client->is_success, 'Transaction is_success as expected');
            ok($client->order_number, 'Transaction order_number found');
            subtest 'A transaction error exists, as expected' => sub {
                plan tests => 2;
                isa_ok($ret,'HASH');
                return unless ref $ret eq 'HASH';
                cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected error result');
            };
        } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
    }
}

SKIP: { # Save
    local $data->{'action'} = 'Tokenize';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Tokenize' => sub {
        plan tests => 2;
        ok($client->is_success, 'Transaction is_success');
        ok($client->card_token, 'Transaction card_token found');
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
    $data->{'card_token'} = $client->card_token; # all tests below will use this
}

SKIP: { # Sale with token
    skip 'No card_token was found', 1 unless $data->{'card_token'};
    local $data->{'action'} = 'Normal Authorization';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization with card_token' => sub {
        plan tests => 3;
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

SKIP: { # Sale with token
    skip 'No card_token was found', 1 unless $data->{'card_token'};
    local $data->{'action'} = 'Normal Authorization';
    local $data->{'first_name'} = 'REJE';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Normal Authorization with card_token' => sub {
        plan tests => 3;
        ok($client->is_success, 'Transaction is_success');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction result exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected result') or diag explain $ret;
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
    $data->{'order_number'} = $client->order_number;
}

SKIP: { # Payment Status
    local $data->{'action'} = 'PayStatus';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = eval { $client->submit() };
    subtest 'PayStatus' => sub {
        plan tests => 3;
        ok($client->is_success, 'Transaction is_success');
        ok($client->order_number, 'Transaction order_number found');
        subtest 'A transaction result exists, as expected' => sub {
            plan tests => 2;
            isa_ok($ret,'HASH');
            return unless ref $ret eq 'HASH';
            cmp_ok($ret->{'result'}, 'eq', '9', 'Found the expected result');
        };
    } or diag explain "Request:\n".$client->server_request,"\nResponse:\n".$client->server_response;
}

SKIP: { # Refund
    skip 'No order_number was found', 1 unless $data->{'order_number'};
    local $data->{'action'} = 'Credit';
    $client->content(%$data);
    push @{$client->{'mocked'}}, {
        action => 'billTransactions',
        login => 'mocked',
        resp => 'ok_duplicate',
    } if $data->{'login'} eq 'mocked';
    my $ret = $client->submit();
    subtest 'Refund' => sub {
        plan tests => 3;
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

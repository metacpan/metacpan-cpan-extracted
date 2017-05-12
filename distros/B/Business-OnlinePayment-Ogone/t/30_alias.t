#!/usr/bin/perl
use strict;
use warnings;
use Test::Most;
use Data::Dumper;
use Business::OnlinePayment;
  
$ENV{OGONE_PSWD} ||= '7n1tt3st';
$ENV{OGONE_PSPID} ||= 'perlunit';
$ENV{OGONE_USERID} ||= 'perltest';

#########################################################################################################
# setup
#########################################################################################################
bail_on_fail; 
    ok($ENV{OGONE_USERID}, "test can only proceed with environment OGONE_USERID set");
bail_on_fail; 
    ok($ENV{OGONE_PSPID}, "test can only proceed with environment OGONE_PSPID set");
bail_on_fail; 
    ok($ENV{OGONE_PSWD}, "test can only proceed with environment OGONE_PSWD set");

my %base_args = (
    PSPID => $ENV{OGONE_PSPID},
    login => $ENV{OGONE_USERID},
    password => $ENV{OGONE_PSWD},
    action => 'authorization only',
    invoice_number => time,
    amount      => '0.01',
    card_number => '4000 0000 0000 0002',
    cvc => '423',
    expiration  => '12/15',
    name => 'Alias Customer 2',
    alias => 'customer_2',
    sha_key => 'xxxtestingx123xpassphrasexxx',
    sha_type => 512,
);

my %alias_args = (
    PSPID => $ENV{OGONE_PSPID},
    login => $ENV{OGONE_USERID},
    password => $ENV{OGONE_PSWD},
    action => 'authorization only',
    cvc => '423',
    invoice_number => time + 1, # make sure both invoice_numbers (base,alias) differ
    amount      => '10',
    alias => 'customer_2',
    sha_key => 'xxxtestingx123xpassphrasexxx',
    sha_type => 512,
);

sub new_test_tx {
    my $tx = new Business::OnlinePayment('Ogone');
    $tx->test_transaction(1);
    return $tx;
}

my $tx = new_test_tx();

#########################################################################################################
# test setup
#########################################################################################################
isa_ok($tx,'Business::OnlinePayment');

#########################################################################################################
# test normal alias flow: authorization only (no post auth), authorization only using alias + post auth
#########################################################################################################
$tx = new_test_tx();

    $tx->content(%base_args); eval { $tx->submit() }; # diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");

$tx = new_test_tx();

    $tx->content(%alias_args); eval { $tx->submit() }; # diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");


$tx = new_test_tx();
$alias_args{action} = 'post authorization';

    $tx->content(%alias_args); eval { $tx->submit() }; # diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");

done_testing();


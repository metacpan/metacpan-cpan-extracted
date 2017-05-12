#!/usr/bin/perl
use strict;
use warnings;
use Test::Most;
use Data::Dumper;
use Business::OnlinePayment;
  
#########################################################################################################
# setup
#########################################################################################################

$ENV{OGONE_PSWD} ||= '7n1tt3st';
$ENV{OGONE_PSPID} ||= 'perlunit';
$ENV{OGONE_USERID} ||= 'perltest';


bail_on_fail; 
    ok($ENV{OGONE_USERID}, "test can only proceed with environment OGONE_USERID set");
bail_on_fail; 
    ok($ENV{OGONE_PSPID}, "test can only proceed with environment OGONE_PSPID set");
bail_on_fail; 
    ok($ENV{OGONE_PSWD}, "test can only proceed with environment OGONE_PSWD set");

my $in = 'abc'.time();
my %base_args = (
    PSPID => $ENV{OGONE_PSPID},
    login => $ENV{OGONE_USERID},
    password => $ENV{OGONE_PSWD},
    action => 'authorization only',
    invoice_number => $in,
    amount      => '0.01',
    card_number => '4000 0000 0000 0002',
    cvc => '423',
    expiration  => '12/15',
    country => 'BE',
    address => 'Nieuwstraat 32',
    name => 'Alias Recurrent Customer',
    alias => 'customer_recur',
    sha_key => 'xxxtestingx123xpassphrasexxx',
    sha_type => 512,
);

my %alias_args = (
    PSPID => $ENV{OGONE_PSPID},
    login => $ENV{OGONE_USERID},
    password => $ENV{OGONE_PSWD},
    action => 'recurrent authorization',
    alias => 'customer_recur',
    name => 'Recurrent Customer Z',
    cvc => '423',
    amount => '42',
    description => "" . localtime,
    subscription_id => $in . 999, #time + 1, # will differ from above time statment
    invoice_number => $in . 999,
    subscription_orderid => $in . 999,
    eci => '9',
    startdate => '2012-01-01',
    enddate => '2013-01-01',
    status => 1,
    period_unit => 'm',
    period_moment => 1,
    period_number => 1,
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
# test recur flow: direct sale which also creates alias, and a recur call to that alias
#########################################################################################################
$tx = new_test_tx();

    $tx->content(%base_args); eval { $tx->submit() }; # diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");

$tx = new_test_tx();

    $tx->content(%alias_args); eval { $tx->submit() };  # diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");


done_testing();

__END__

# vim: ft=perl

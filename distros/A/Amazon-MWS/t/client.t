#!perl

use strict;
use warnings;
use utf8;
use Amazon::MWS::Client;

use Test::More;
use Test::Deep;
use Test::Warnings;

my $mws = Amazon::MWS::Client->new(
    merchant_id => '__MERCHANT_ID__',
    access_key_id => '12341234',
    secret_key => '123412341234',
    marketplace_id => '123412341234',
 );

my $status = $mws->GetServiceStatus;

cmp_deeply $status, any(qw/GREEN GREEN_I YELLOW RED/), "Test response of GetServiceStatus API method";

done_testing;

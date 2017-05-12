#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Business::PayPoint;
use Data::Dumper;

my $bp = Business::PayPoint->new();
$bp->set_credentials( 'secpay', 'secpay', 'secpay' );

my %result = $bp->validateCardFull(
    'trans_id'    => 'tran0001',
    'ip'          => '127.0.0.1',
    'name'        => 'Mr Cardholder',
    'card_number' => '4444333322221111',
    'amount'      => '50.00',
    'expiry_date' => '0115',
    'billing' =>
"name=Fred+Bloggs,company=Online+Shop+Ltd,addr_1=Dotcom+House,addr_2=London+Road,city=Townville,state=Countyshire,post_code=AB1+C23,tel=01234+567+890,fax=09876+543+210,email=somebody%40secpay.com,url=http%3A%2F%2Fwww.somedomain.com",
    'options' => 'test_status=true,dups=false,card_type=Visa,cv2=123'
);

print Dumper( \%result );

1;

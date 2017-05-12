#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More tests => 1;

use Business::OnlinePayment;

my %content = (                                                                 
    action         => "Normal Authorization",                                   
    type           => "CC",                                                     
    description    => "Business::OnlinePayment::IATSPayments test",     
    card_number    => '4111111111111111',
    cvv2           => '123',
    expiration     => '12/20',
    amount         => '1.00',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '1234 Soybean Ln.',
    city           => 'Soyville',
    state          => 'CA', #where else?
    zip            => '54545',
);                                                                              

my $tx = new Business::OnlinePayment( 'IATSPayments' );

$tx->content( %content );

$tx->test_transaction(1);

$tx->submit;

is( $tx->is_success, 1, 'Test transaction successful')
  or diag('iATS Payments error: '. $tx->error_message);
            
1;

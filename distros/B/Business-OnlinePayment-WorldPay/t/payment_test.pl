#!/usr/bin/perl

use strict;
use warnings;

use blib;
use Business::OnlinePayment;

my %content = (
    installation  => '123456',                      # InstallationID
    login         => 'ABCMARKETING',                # MerchantCode
    password      => 'hYakr1234dDD',                # XML Password

    action        => 'payment', 
    description   => 'A dozen roses',     
    amount        => '10.00',                
    currency      => 'EUR',                  
    order_number  => 'A13034',

    name          => 'Sam Smith',       
    address       => '123 Disk Drive',
    city          => 'Whoville',
#   state         => 'NY',
    zip           => '10003',
    country       => 'FR',                      
 
    type          => 'Visa',                 
    card_number   => '4484-0700-0000-0000',        
    exp_date      => '02/11',
    cvc           => '485',
);

#################################################

my $tx = Business::OnlinePayment->new("WorldPay");

$tx->debug(1);

$tx->content( %content );

# $tx->test_transaction(1);

$tx->submit();

print "\nStandard B::OP attributes:\n";

print "test_transaction = ", $tx->test_transaction, "\n";
print "transaction_type = ", $tx->transaction_type, "\n";
print "is_success       = ", $tx->is_success,       "\n";
print "authorization    = ", $tx->authorization,    "\n";
print "result_code      = ", $tx->result_code,      "\n";
print "error_message    = ", $tx->error_message,    "\n";
print "server           = ", $tx->server,           "\n";
print "port             = ", $tx->port,             "\n";
print "path             = ", $tx->path,             "\n";
print "server_response  = ", $tx->server_response,  "\n\n";

print "-" x 80, "\n\n";

print "Additional B::OP::WorldPay attributes:\n";

print "status_code      = ", $tx->status_code,     "\n";
print "status_detail    = ", $tx->status_detail,   "\n";
print "cvv2_response    = ", $tx->cvv2_response,   "\n";
print "avs_code         = ", $tx->avs_code,        "\n";
print "risk_score       = ", $tx->risk_score,      "\n\n";

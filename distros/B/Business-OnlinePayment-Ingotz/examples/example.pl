#!/usr/bin/perl

use strict;
use lib '../lib';

use Business::OnlinePayment;

#$Business::OnlinePayment::DEBUG = 1;

my $trans = Business::OnlinePayment->new('Ingotz');
$trans->content(
  login          => '6277177700000000',
  action         => 'raw',
  amount         => '199',
  description    => 'test',
  card_number    => '312312312312345',
  pin            => '333',
);

$trans->submit();

if ($trans->is_success){
  print "Transaction has been processed successfully\n"; 
}
else{
  print "Error: ".$trans->error_message(),"\n"; 
}

#!/usr/bin/perl -w

use Test::More;
require 't/lib/test_account.pl';

my($login, $password) = test_account_or_skip();
plan tests => 2;

use_ok 'Business::OnlinePayment';

my $tx = Business::OnlinePayment->new('WesternACH');
$tx->content(
  type      =>  'echeck',
  login     =>  $login,
  password  =>  $password, 
  action    =>  'Normal Authorization',
  description => 'Business::OnlinePayment checking test',
  amount    =>  '10.00',
  invoice_number => '10999',
  customer_id => 'nobody',
  first_name  => 'John',
  last_name => 'Doe',
  address   => '123 Anywhere',
  city      => 'Sacramento',
  state     => 'CA',
  zip       => '95824',
  account_number => '100012345678',
  routing_code  => '307070005',
  account_type  => 'Checking',
  check_number => '1277'
);
$tx->submit();

ok($tx->is_success()) or diag $tx->error_message;


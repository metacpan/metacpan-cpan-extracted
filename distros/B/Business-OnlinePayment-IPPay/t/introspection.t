#!/usr/bin/perl -w

use Test::More;

eval 'use Business::OnlinePayment 3.01;';
if ( $@ ) {
  plan skip_all => 'Business::OnlinePayment 3.01+ not available';
} else {
  plan tests => 1;
}

my($login, $password, @opts) = ('TESTMERCHANT', '',
                                'default_Origin' => 'RECURRING' );

my $tx = Business::OnlinePayment->new("IPPay", @opts);

ok( $tx->info('CC_void_requires_card') == 1, 'CC_void_requires_card introspection' );

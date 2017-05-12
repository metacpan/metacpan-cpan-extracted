#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::IPayment' ) || print "Bail out!\n";
}

diag( "Testing Business::OnlinePayment::IPayment $Business::OnlinePayment::IPayment::VERSION, Perl $], $^X" );

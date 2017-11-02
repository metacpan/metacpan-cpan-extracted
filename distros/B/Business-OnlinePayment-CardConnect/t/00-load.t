#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::CardConnect' );
}

diag( "Testing Business::OnlinePayment::CardConect $Business::OnlinePayment::CardConnect::VERSION, Perl $], $^X" );

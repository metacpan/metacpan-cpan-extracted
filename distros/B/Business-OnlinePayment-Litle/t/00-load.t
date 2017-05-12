#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::Litle' );
}

diag( "Testing Business::OnlinePayment::Litle $Business::OnlinePayment::Litle::VERSION, Perl $], $^X" );

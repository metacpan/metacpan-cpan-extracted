#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::CardFortress' ) || print "Bail out!
";
}

diag( "Testing Business::OnlinePayment::CardFortress $Business::OnlinePayment::CardFortress::VERSION, Perl $], $^X" );

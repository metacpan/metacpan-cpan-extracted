#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::IATSPayments' ) || print "Bail out!
";
}

diag( "Testing Business::OnlinePayment::IATSPayments $Business::OnlinePayment::IATSPayments::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::FirstDataGlobalGateway' ) || print "Bail out!
";
}

diag( "Testing Business::OnlinePayment::FirstDataGlobalGateway $Business::OnlinePayment::FirstDataGlobalGateway::VERSION, Perl $], $^X" );

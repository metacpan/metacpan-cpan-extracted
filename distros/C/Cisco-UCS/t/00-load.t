#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cisco::UCS' ) || print "Bail out!
";
}

diag( "Testing Cisco::UCS $Cisco::UCS::VERSION, Perl $], $^X" );

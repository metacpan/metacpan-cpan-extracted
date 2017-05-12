#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Timecube' ) || print "Bail out!
";
}

diag( "Testing Acme::Timecube $Acme::Timecube::VERSION, Perl $], $^X" );

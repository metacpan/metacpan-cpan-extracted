#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::EvilLicense' ) || print "Bail out!
";
}

diag( "Testing Acme::EvilLicense $Acme::EvilLicense::VERSION, Perl $], $^X" );

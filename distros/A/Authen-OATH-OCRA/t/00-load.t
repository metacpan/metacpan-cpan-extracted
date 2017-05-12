#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::OATH::OCRA' ) || print "Bail out!
";
}

diag( "Testing Authen::OATH::OCRA $Authen::OATH::OCRA::VERSION, Perl $], $^X" );

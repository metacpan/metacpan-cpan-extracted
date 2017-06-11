#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::EECDH' ) || print "Bail out!
";
}

diag( "Testing Crypt::EECDH $Crypt::EECDH::VERSION, Perl $], $^X" );

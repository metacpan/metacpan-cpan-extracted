#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::HTTP::Signature' ) || print "Bail out!\n";
}

diag( "Testing Authen::HTTP::Signature $Authen::HTTP::Signature::VERSION, Perl $], $^X" );

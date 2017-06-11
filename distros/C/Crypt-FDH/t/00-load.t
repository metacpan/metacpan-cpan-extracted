#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::FDH' ) || print "Bail out!
";
}

diag( "Testing Crypt::FDH $Crypt::FDH::VERSION, Perl $], $^X" );

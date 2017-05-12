#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::FNA' ) || print "Bail out!\n";
    #use_ok( 'Crypt::FNA::Validation' ) || print "Bail out!\n";
}

diag( "Testing Crypt::FNA $Crypt::FNA::VERSION, Perl $], $^X" );

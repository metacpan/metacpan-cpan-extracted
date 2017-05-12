#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::FNA::Async' ) || print "Bail out!\n";
}

diag( "Testing Crypt::FNA::Async $Crypt::FNA::Async::VERSION, Perl $], $^X" );

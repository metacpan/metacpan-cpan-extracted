#!perl

use Test::More tests => 1;
use Test::Carp;


BEGIN {
    use_ok( 'Data::ESN' ) || print "Bail out!\n";
}

diag( "Testing Data::ESN $Data::ESN::VERSION, Perl $], $^X" );



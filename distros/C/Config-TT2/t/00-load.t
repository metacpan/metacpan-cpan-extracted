#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::TT2' ) || print "Bail out!\n";
}

diag( "Testing Config::TT2 $Config::TT2::VERSION, Perl $], $^X" );

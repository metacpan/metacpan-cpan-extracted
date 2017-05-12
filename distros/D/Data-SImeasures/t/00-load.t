#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SImeasures' ) || print "Bail out!\n";
}

diag( "Testing Data::SImeasures $Data::SImeasures::VERSION, Perl $], $^X" );

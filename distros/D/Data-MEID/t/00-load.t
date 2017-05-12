#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::MEID' ) || print "Bail out!\n";
}

diag( "Testing Data::MEID $Data::MEID::VERSION, Perl $], $^X" );

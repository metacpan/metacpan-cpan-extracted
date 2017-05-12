#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::XHash' ) || print "Bail out!\n";
}

diag( "Testing Data::XHash $Data::XHash::VERSION, Perl $], $^X" );

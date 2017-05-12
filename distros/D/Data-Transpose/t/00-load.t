#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Transpose' ) || print "Bail out!\n";
}

diag( "Testing Data::Transpose $Data::Transpose::VERSION, Perl $], $^X" );

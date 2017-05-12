#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::PrintUtils' ) || print "Bail out!\n";
}

diag( "Testing Data::PrintUtils $Data::PrintUtils::VERSION, Perl $], $^X" );

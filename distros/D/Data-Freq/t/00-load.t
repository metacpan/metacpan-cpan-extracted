#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Freq' ) || print "Bail out!\n";
}

diag( "Testing Data::Freq $Data::Freq::VERSION, Perl $], $^X" );

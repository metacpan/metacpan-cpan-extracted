#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::micro' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::micro $Data::SIprefixes::micro::VERSION, Perl $], $^X" );

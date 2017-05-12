#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::milli' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::milli $Data::SIprefixes::milli::VERSION, Perl $], $^X" );

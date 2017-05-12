#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::atto' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::atto $Data::SIprefixes::atto::VERSION, Perl $], $^X" );

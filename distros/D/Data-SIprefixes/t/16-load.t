#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SIprefixes::tera' ) || print "Bail out!\n";
}

diag( "Testing Data::SIprefixes::tera $Data::SIprefixes::tera::VERSION, Perl $], $^X" );

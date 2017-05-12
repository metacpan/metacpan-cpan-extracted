#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DNS::PunyDNS' ) || print "Bail out!\n";
}

diag( "Testing DNS::PunyDNS $DNS::PunyDNS::VERSION, Perl $], $^X" );

#!perl 
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Coinbase' ) || print "Bail out!\n";
}

#diag( "Testing Acme::Coinbase $Acme::Coinbase::VERSION, Perl $], $^X" );


#!perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::List::CarCdr' ) || print "Bail out!\n";
}

diag( "Testing Acme::List::CarCdr $Acme::List::CarCdr::VERSION, Perl $], $^X" );

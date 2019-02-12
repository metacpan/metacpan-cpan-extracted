#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Backwards' ) || print "Bail out!\n";
}

diag( "Testing Acme::Backwards $Acme::Backwards::VERSION, Perl $], $^X" );

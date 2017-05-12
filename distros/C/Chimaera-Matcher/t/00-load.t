#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Chimaera::Matcher' ) || print "Can't find the Chimaera::Matcher module!\n";
}

diag( "Testing Chimaera-Matcher $Chimaera::Matcher::VERSION, Perl $], $^X" );

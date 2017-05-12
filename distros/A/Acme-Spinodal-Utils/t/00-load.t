#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Spinodal::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::Spinodal::Utils $Acme::Spinodal::Utils::VERSION, Perl $], $^X" );

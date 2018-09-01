#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::NAHCNUJ::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::NAHCNUJ::Utils $Acme::NAHCNUJ::Utils::VERSION, Perl $], $^X" );

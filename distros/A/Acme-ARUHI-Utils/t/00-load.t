#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::ARUHI::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::ARUHI::Utils $Acme::ARUHI::Utils::VERSION, Perl $], $^X" );

#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::GLOINBG::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::GLOINBG::Utils $Acme::GLOINBG::Utils::VERSION, Perl $], $^X" );

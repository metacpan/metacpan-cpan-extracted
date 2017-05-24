#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::DotDotGone' ) || print "Bail out!\n";
}

diag( "Testing Acme::DotDotGone $Acme::DotDotGone::VERSION, Perl $], $^X" );

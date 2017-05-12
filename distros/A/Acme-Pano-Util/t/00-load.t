#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Pano::Util' ) || print "Bail out!\n";
}

diag( "Testing Acme::Pano::Util $Acme::Pano::Util::VERSION, Perl $], $^X" );

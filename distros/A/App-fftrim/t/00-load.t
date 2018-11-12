#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::fftrim' ) || print "Bail out!\n";
}

diag( "Testing App::fftrim v$App::fftrim::VERSION, Perl $], $^X" );

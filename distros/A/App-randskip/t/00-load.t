#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::randskip' ) || print "Bail out!\n";
}

diag( "Testing App::randskip $App::randskip::VERSION, Perl $], $^X" );

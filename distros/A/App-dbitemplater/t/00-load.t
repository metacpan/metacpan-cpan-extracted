#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::dbitemplater' ) || print "Bail out!\n";
}

diag( "Testing App::dbitemplater $App::dbitemplater::VERSION, Perl $], $^X" );

#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::remotediff' ) || print "Bail out!\n";
}

diag( "Testing App::remotediff $App::remotediff::VERSION, Perl $], $^X" );

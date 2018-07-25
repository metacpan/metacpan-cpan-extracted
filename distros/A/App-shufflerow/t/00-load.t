#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::shufflerow' ) || print "Bail out!\n";
}

diag( "Testing App::shufflerow $App::shufflerow::VERSION, Perl $], $^X" );

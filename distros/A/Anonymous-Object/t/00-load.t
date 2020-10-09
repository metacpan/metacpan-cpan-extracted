#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Anonymous::Object' ) || print "Bail out!\n";
}

diag( "Testing Anonymous::Object $Anonymous::Object::VERSION, Perl $], $^X" );

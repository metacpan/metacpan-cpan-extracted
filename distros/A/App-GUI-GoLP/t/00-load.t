#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::GUI::GoLP' ) || print "Bail out!\n";
}

diag( "Testing App::GUI::GoLP $App::GUI::GoLP::VERSION, Perl $], $^X" );

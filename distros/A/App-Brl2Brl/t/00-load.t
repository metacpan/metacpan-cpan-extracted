#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Brl2Brl' ) || print "Bail out!\n";
}

diag( "Testing App::Brl2Brl $App::Brl2Brl::VERSION, Perl $], $^X" );

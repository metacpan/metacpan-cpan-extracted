#!perl
use 5.016;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Tarotplane' ) || print "Bail out!\n";
}

diag( "Testing App::Tarotplane $App::Tarotplane::VERSION, Perl $], $^X" );

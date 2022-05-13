#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Cheats' ) || print "Bail out!\n";
}

diag( "Testing App::Cheats $App::Cheats::VERSION, Perl $], $^X" );

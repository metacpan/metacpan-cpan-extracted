#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::HashMake' ) || print "Bail out!\n";
}

diag( "Testing App::HashMake $App::HashMake::VERSION, Perl $], $^X" );

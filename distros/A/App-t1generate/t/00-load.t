#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::t1generate' ) || print "Bail out!\n";
}

diag( "Testing App::t1generate $App::t1generate::VERSION, Perl $], $^X" );

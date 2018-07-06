#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::t2generate' ) || print "Bail out!\n";
}

diag( "Testing App::t2generate $App::t2generate::VERSION, Perl $], $^X" );

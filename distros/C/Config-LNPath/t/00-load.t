#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::LNPath' ) || print "Bail out!\n";
}

diag( "Testing Config::LNPath $Config::LNPath::VERSION, Perl $], $^X" );

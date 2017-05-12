#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::From' ) || print "Bail out!\n";
}

diag( "Testing Config::From $Config::From::VERSION, Perl $], $^X" );

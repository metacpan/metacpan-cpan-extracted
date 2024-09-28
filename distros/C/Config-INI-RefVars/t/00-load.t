#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::INI::RefVars' ) || print "Bail out!\n";
}

diag( "Testing Config::INI::RefVars $Config::INI::RefVars::VERSION, Perl $], $^X" );

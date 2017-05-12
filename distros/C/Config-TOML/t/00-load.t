#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::TOML' ) || print "Bail out!\n";
}

diag( "Testing Config::TOML $Config::TOML::VERSION, Perl $], $^X" );

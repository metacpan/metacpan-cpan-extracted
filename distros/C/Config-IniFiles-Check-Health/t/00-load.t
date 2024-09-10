#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use lib './lib';

plan tests => 1;

BEGIN {
    use_ok( 'Config::IniFiles::Check::Health' ) || print "Bail out!\n";
}

diag( "Testing Config::IniFiles::Check::Health $Config::IniFiles::Check::Health::VERSION, Perl $], $^X" );


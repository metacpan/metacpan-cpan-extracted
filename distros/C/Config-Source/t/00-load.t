use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::Source' ) || print "Bail out!\n";
}

diag( "Testing Config::Source $Config::Source::VERSION, Perl $], $^X" );

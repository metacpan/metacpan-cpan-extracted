#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Compiled::Params::OO' ) || print "Bail out!\n";
}

diag( "Testing Compiled::Params::OO $Compiled::Params::OO::VERSION, Perl $], $^X" );

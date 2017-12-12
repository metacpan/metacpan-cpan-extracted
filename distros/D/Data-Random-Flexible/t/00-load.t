#!perl -T
use 5.020;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Random::Flexible' ) || print "Bail out!\n";
}

diag( "Testing Data::Random::Flexible $Data::Random::Flexible::VERSION, Perl $], $^X" );

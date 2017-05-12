#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CatalystX::ASP' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::ASP $CatalystX::ASP::VERSION, Perl $], $^X" );

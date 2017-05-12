#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bundle::Padre::Plugin' ) || print "Bail out!\n";
}

diag( "Testing Bundle::Padre::Plugin $Bundle::Padre::Plugin::VERSION, Perl $], $^X" );

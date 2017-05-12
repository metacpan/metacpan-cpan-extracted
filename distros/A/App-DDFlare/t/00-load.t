#!perl -T
use v5.10;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::DDFlare' ) || print "Bail out!\n";
}

diag( "Testing App::DDFlare $App::DDFlare::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Unicheck::Modules::MongoDB' ) || print "Bail out!\n";
}

diag( "Testing App::Unicheck::Modules::MongoDB $App::Unicheck::Modules::MongoDB::VERSION, Perl $], $^X" );

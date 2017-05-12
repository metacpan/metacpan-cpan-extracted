#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Unicheck::Modules::MySQL' ) || print "Bail out!\n";
}

diag( "Testing App::Unicheck::Modules::MySQL $App::Unicheck::Modules::MySQL::VERSION, Perl $], $^X" );

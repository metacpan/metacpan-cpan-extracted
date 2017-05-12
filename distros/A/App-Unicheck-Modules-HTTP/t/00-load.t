#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Unicheck::Modules::HTTP' ) || print "Bail out!\n";
}

diag( "Testing App::Unicheck::Modules::HTTP $App::Unicheck::Modules::HTTP::VERSION, Perl $], $^X" );

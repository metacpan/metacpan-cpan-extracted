#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::OpenMbox::Test' ) || print "Bail out!\n";
}

diag( "Testing App::OpenMbox::Test $App::OpenMbox::Test::VERSION, Perl $], $^X" );

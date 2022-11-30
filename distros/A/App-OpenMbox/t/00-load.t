#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::OpenMbox' ) || print "Bail out!\n";
}

diag( "Testing App::OpenMbox $App::OpenMbox::VERSION, Perl $], $^X" );

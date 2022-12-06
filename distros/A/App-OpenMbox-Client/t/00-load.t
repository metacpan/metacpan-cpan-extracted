#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::OpenMbox::Client' ) || print "Bail out!\n";
}

diag( "Testing App::OpenMbox::Client $App::OpenMbox::Client::VERSION, Perl $], $^X" );

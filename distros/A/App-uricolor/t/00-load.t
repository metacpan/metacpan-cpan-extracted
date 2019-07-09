#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::uricolor' ) || print "Bail out!\n";
}

diag( "Testing App::uricolor $App::uricolor::VERSION, Perl $], $^X" );

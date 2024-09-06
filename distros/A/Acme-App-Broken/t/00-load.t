#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::App::Broken' ) || print "Bail out!\n";
}

diag( "Testing Acme::App::Broken $Acme::App::Broken::VERSION, Perl $], $^X" );

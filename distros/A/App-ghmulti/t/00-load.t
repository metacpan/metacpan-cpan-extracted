#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::ghmulti' ) || print "Bail out!\n";
}

diag( "Testing App::ghmulti $App::ghmulti::VERSION, Perl $], $^X" );

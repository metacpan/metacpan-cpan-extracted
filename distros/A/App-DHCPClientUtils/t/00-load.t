#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::DHCPClientUtils' ) || print "Bail out!\n";
}

diag( "Testing App::DHCPClientUtils $App::DHCPClientUtils::VERSION, Perl $], $^X" );

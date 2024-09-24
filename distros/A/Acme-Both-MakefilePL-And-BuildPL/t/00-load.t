#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Both::MakefilePL::And::BuildPL' ) || print "Bail out!\n";
}

diag( "Testing Acme::Both::MakefilePL::And::BuildPL $Acme::Both::MakefilePL::And::BuildPL::VERSION, Perl $], $^X" );

#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Acme::Tau') || print "Bail out!\n";
}

diag("Testing Acme::Tau $Acme::Tau::VERSION, Perl $], $^X");

is( sprintf( "%.2f", Acme::Tau->VERSION ), 6.28, "check version" );

plan tests => int( $Acme::Tau::VERSION / $Acme::Pi::VERSION );

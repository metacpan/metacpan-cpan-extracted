#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Automatix' ) || print "Bail out!\n";
}

diag( "Testing Acme::Automatix $Acme::Automatix::VERSION, Perl $], $^X" );

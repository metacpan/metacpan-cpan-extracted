#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Inabajun::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::Inabajun::Utils $Acme::Inabajun::Utils::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Mandolion::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::Mandolion::Utils $Acme::Mandolion::Utils::VERSION, Perl $], $^X" );

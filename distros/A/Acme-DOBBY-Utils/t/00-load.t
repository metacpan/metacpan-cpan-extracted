#!perl
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::DOBBY::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::DOBBY::Utils $Acme::DOBBY::Utils::VERSION, Perl $], $^X" );

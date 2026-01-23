#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::ExtUtils::XSOne::Test::Calculator' ) || print "Bail out!\n";
}

diag( "Testing Acme::ExtUtils::XSOne::Test::Calculator $Acme::ExtUtils::XSOne::Test::Calculator::VERSION, Perl $], $^X" );

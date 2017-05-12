#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DNS::RName::Converter' ) || print "Bail out!\n";
}

diag( "Testing DNS::RName::Converter $DNS::RName::Converter::VERSION, Perl $], $^X" );

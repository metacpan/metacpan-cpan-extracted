#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DNS::SerialNumber::Check' ) || print "Bail out!
";
}

diag( "Testing DNS::SerialNumber::Check $DNS::SerialNumber::Check::VERSION, Perl $], $^X" );

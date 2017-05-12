#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DNS::Record::Check' ) || print "Bail out!
";
}

diag( "Testing DNS::Record::Check $DNS::Record::Check::VERSION, Perl $], $^X" );

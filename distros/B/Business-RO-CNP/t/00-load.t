#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::RO::CNP' ) || print "Bail out!
";
}

diag( "Testing Business::RO::CNP $Business::RO::CNP::VERSION, Perl $], $^X" );

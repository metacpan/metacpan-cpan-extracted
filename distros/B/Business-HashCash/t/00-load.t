#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::HashCash' ) || print "Bail out!
";
}

diag( "Testing Business::HashCash $Business::HashCash::VERSION, Perl $], $^X" );

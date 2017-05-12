#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::Bitcoin' ) || print "Bail out!
";
}

diag( "Testing Business::Bitcoin $Business::Bitcoin::VERSION, Perl $], $^X" );

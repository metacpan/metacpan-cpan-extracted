#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::HashCash' ) || print "Bail out!
";
}

diag( "Testing Crypt::HashCash $Crypt::HashCash::VERSION, Perl $], $^X" );

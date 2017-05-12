#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Backed_Objects' ) || print "Bail out!
";
}

diag( "Testing Backed_Objects $Backed_Objects::VERSION, Perl $], $^X" );

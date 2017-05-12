#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AE::AdHoc' ) || print "Bail out!
";
}

diag( "Testing AE::AdHoc $AE::AdHoc::VERSION, Perl $], $^X" );

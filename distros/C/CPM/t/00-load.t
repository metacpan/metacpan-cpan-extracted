#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CPM' ) || print "Bail out!
";
}

diag( "Testing CPM $CPM::VERSION, Perl $], $^X" );

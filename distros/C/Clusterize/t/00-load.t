#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Clusterize' ) || print "Bail out!
";
    use_ok( 'Clusterize::Pattern' ) || print "Bail out!
";
}

diag( "Testing Clusterize $Clusterize::VERSION, Perl $], $^X" );

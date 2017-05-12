#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CohortExplorer' ) || print "Bail out!\n";
}

diag( "Testing CohortExplorer $CohortExplorer::VERSION, Perl $], $^X" );

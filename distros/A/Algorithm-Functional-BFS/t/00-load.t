#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Algorithm::Functional::BFS' ) || print "Bail out!
";
}

diag( "Testing Algorithm::Functional::BFS $Algorithm::Functional::BFS::VERSION, Perl $], $^X" );

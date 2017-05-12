#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Algorithm::Shape::RandomTree' ) || print "Bail out!
";
}

diag( "Testing Algorithm::Shape::RandomTree $Algorithm::Shape::RandomTree::VERSION, Perl $], $^X" );

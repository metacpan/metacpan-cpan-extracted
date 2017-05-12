#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Tree' ) || print "Bail out!
";
}

diag( "Testing Data::Tree $Data::Tree::VERSION, Perl $], $^X" );

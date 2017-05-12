#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::Gonzales' ) || print "Bail out!
";
}

diag( "Testing Bio::Gonzales $Bio::Gonzales::VERSION, Perl $], $^X" );

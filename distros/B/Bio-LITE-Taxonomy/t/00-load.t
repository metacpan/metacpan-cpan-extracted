#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::LITE::Taxonomy' ) || print "Bail out!
";
}

diag( "Testing Bio::LITE::Taxonomy $Bio::LITE::Taxonomy::VERSION, Perl $], $^X" );

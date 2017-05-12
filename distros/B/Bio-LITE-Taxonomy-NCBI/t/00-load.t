#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::LITE::Taxonomy::NCBI' ) || print "Bail out!
";
}

diag( "Testing Bio::LITE::Taxonomy::NCBI $Bio::LITE::Taxonomy::NCBI::VERSION, Perl $], $^X" );

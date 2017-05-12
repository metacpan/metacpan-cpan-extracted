#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::LITE::Taxonomy::NCBI::Gi2taxid' ) || print "Bail out!
";
}

diag( "Testing Bio::LITE::Taxonomy::NCBI::Gi2taxid $Bio::LITE::Taxonomy::NCBI::Gi2taxid::VERSION, Perl $], $^X" );

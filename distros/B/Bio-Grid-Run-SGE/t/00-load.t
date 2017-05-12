#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::Grid::Run::SGE' ) || print "Bail out!
";
}

diag( "Testing Bio::Grid::Run::SGE $Bio::Grid::Run::SGE::VERSION, Perl $], $^X" );

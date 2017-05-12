#!perl -T

use Test::More tests => 9;

BEGIN {
	use_ok( 'Bio::DOOP::DOOP' );
	use_ok( 'Bio::DOOP::DBSQL' );
	use_ok( 'Bio::DOOP::Cluster' );
	use_ok( 'Bio::DOOP::ClusterSubset' );
	use_ok( 'Bio::DOOP::Motif' );
	use_ok( 'Bio::DOOP::Sequence' );
	use_ok( 'Bio::DOOP::SequenceFeature' );
	use_ok( 'Bio::DOOP::Util::Search' );
	use_ok( 'Bio::DOOP::Graphics::Feature' );
}

diag( "Testing Bio::DOOP::DOOP $Bio::DOOP::DOOP::VERSION, Perl $], $^X" );

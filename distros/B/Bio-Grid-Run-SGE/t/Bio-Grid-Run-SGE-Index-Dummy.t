use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Bio::Grid::Run::SGE::Index::Dummy'); }

my $index = Bio::Grid::Run::SGE::Index::Dummy->new( idx_file => undef )->create;

my @letters = ( 'a' .. 'z' );
for ( my $i = 0; $i < $index->num_elem; $i++ ) {
  is( $index->get_elem($i), $letters[$i] );
}

done_testing();


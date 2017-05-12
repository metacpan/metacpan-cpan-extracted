use warnings;
use strict;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Compare qw/compare/;
use File::Spec::Functions qw/catfile rel2abs/;

BEGIN { use_ok('Bio::Grid::Run::SGE::Index::List'); }

my $td = tempdir( CLEANUP => 1 );

{
  my $idx = Bio::Grid::Run::SGE::Index::List->new(
    'writeable' => 1,
    'idx_file'  => catfile( $td, 'test.idx' ),
  );

  my @letters = ( 'a' .. 'z' );

  $idx->create( \@letters );

  is( $idx->num_elem, scalar @letters );

  for ( my $i = 0; $i < $idx->num_elem; $i++ ) {
    is_deeply( $idx->get_elem($i), [ $letters[$i] ] );
  }
}

{
  my $idx = Bio::Grid::Run::SGE::Index::List->new(
    'writeable'  => 1,
    'idx_file'   => catfile( $td, 'test.idx' ),
    'chunk_size' => 3,
  );

  my @letters        = ( 'a' .. 'z' );
  my @letters_chunked = (
    [ 'a', 'b', 'c' ],
    [ 'd', 'e', 'f' ],
    [ 'g', 'h', 'i' ],
    [ 'j', 'k', 'l' ],
    [ 'm', 'n', 'o' ],
    [ 'p', 'q', 'r' ],
    [ 's', 't', 'u' ],
    [ 'v', 'w', 'x' ],
    [ 'y', 'z' ]
  );

  $idx->create( \@letters );

  is( $idx->num_elem, 9 );

  for ( my $i = 0; $i < $idx->num_elem; $i++ ) {
    is_deeply( $idx->get_elem($i), $letters_chunked[$i] );
  }
}

done_testing();


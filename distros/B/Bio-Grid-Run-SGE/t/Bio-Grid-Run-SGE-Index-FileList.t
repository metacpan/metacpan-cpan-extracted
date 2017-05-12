use warnings;
use strict;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Compare qw/compare/;
use File::Spec::Functions qw/catfile rel2abs/;

BEGIN { use_ok('Bio::Grid::Run::SGE::Index::FileList'); }

my $td = tempdir( CLEANUP => 1 );

my $idx = Bio::Grid::Run::SGE::Index::FileList->new(
  'writeable' => 1,
  'idx_file'  => catfile( $td, 'test.idx' ),
);

my @files
  = ( 't/data/test.fa', 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-0.ref.fa', 't/data/test.fa' );
$idx->create( \@files );

my $range_tmp = catfile( $td, 'range.fa' );

is( $idx->num_elem, 3 );

for my $elem_idx ( 0 .. 2 ) {
  my $data = $idx->get_elem($elem_idx);
  is_deeply( $data, [ rel2abs( $files[$elem_idx] ) ], 'elem data test' );
}

done_testing();
#TESTS

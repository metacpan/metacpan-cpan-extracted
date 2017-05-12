use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;
use File::Spec;
use Bio::Grid::Run::SGE::Index;
use File::Compare qw/compare/;
use Bio::Gonzales::Seq::IO qw/faslurp faspew/;
use Bio::Grid::Run::SGE::Index::Dummy;
use Bio::Grid::Run::SGE::Index::FileList;

BEGIN { use_ok('Bio::Grid::Run::SGE::Iterator::AvsB'); }

my $tmp_dir = tempdir( CLEANUP => 1 );
my $idx_file_a = catfile( $tmp_dir, 'a.idx' );
my $idx_file_b = catfile( $tmp_dir, 'b.idx' );

my $idx_a = Bio::Grid::Run::SGE::Index->new(
  format    => 'General',
  sep       => '^>',
  idx_file  => $idx_file_a,
  writeable => 1,
);
$idx_a->create( ['t/data/test.fa'] );

my $idx_b = Bio::Grid::Run::SGE::Index->new(
  format    => 'General',
  sep       => '^>',
  idx_file  => $idx_file_b,
  writeable => 1,
);

my $seqs = faslurp('t/data/test.fa');

mkdir $tmp_dir;
my $data_reversed_file = catfile( $tmp_dir, 'test_reversed.fa' );
faspew( $data_reversed_file, reverse(@$seqs) );
$idx_b->create( [$data_reversed_file] );

# combination bug
{
  my $idx0
    = Bio::Grid::Run::SGE::Index::Dummy->new( idx => [ 1 .. 42 ], idx_file => '/tmp/dummy_idx.0' )->create;
  is( $idx0->num_elem, 42 );
  my $idx1
    = Bio::Grid::Run::SGE::Index::Dummy->new( idx => [ 1 .. 55 ], idx_file => '/tmp/dummy_idx.1' )->create;
  is( $idx1->num_elem, 55 );
  my $it = Bio::Grid::Run::SGE::Iterator::AvsB->new( indices => [ $idx0, $idx1 ] );

  is( $it->num_comb, 42 * 55 );
  $it->start( [ 0, 42 * 55 - 1 ] );
  for ( my $i = 1; $i <= 42; $i++ ) {
    for ( my $j = 1; $j <= 55; $j++ ) {
      my $comb = $it->next_comb;
      is_deeply( $comb, [ $i, $j ] );
    }
  }
  ok( !defined( $it->next_comb ) );
}

my $it_1 = Bio::Grid::Run::SGE::Iterator::AvsB->new( indices => [ $idx_a, $idx_b ] );

is( $it_1->num_comb, 45 * 45 );

$it_1->start( [ 0, 99 ] );

my $range_0_100 = catfile( $tmp_dir, "range-0-100.fa" );
open my $range_0_100_fh, '>', $range_0_100 or die "Can't open filehandle: $!";
while ( my $comb = $it_1->next_comb ) {
  print $range_0_100_fh ( split( /\n/, $comb->[0] ) )[0], "\t", ( split( /\n/, $comb->[1] ) )[0], "\n";
}
$range_0_100_fh->close;

my $ref_file = catfile( $tmp_dir, 'range-0-100.ref.fa' );
open my $ref_fh, '>', $ref_file or die "Can't open filehandle: $!";
#create reference file
my $total = 0;
for ( my $i = 0; $total < 100 && $i < @$seqs; $i++ ) {
  for ( my $j = @$seqs - 1; $j >= 0 && $total < 100; $j-- ) {
    print $ref_fh ">", $seqs->[$i]->def, "\t>", $seqs->[$j]->def, "\n";
    $total++;
  }
}
$ref_fh->close;

is( compare( $range_0_100, $ref_file ), 0, 'range 0 .. 100' );

{

  my $idx1 = Bio::Grid::Run::SGE::Index::FileList->new(
    'writeable' => 1,
    'idx_file'  => catfile( $tmp_dir, 'testfidx.idx' ),
  );
  my @files
    = ( 't/data/test.fa', 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-0.ref.fa', 't/data/test.fa' );
  $idx1->create( \@files );

  is( $idx1->num_elem, 3 );

  my $idx0
    = Bio::Grid::Run::SGE::Index::Dummy->new( idx => [ 1 .. 42 ], idx_file => '/tmp/dummy_idx.10' )->create;
  is( $idx0->num_elem, 42 );

  my $it = Bio::Grid::Run::SGE::Iterator::AvsB->new( indices => [ $idx0, $idx1 ] );

  is( $it->num_comb, 3 * 42 );
  $it->start( [ 0, 42 * 3 - 1 ] );
  for ( my $i = 1; $i <= 42; $i++ ) {
    for ( my $j = 1; $j <= 3; $j++ ) {
      my $comb = $it->next_comb;
      is_deeply( $comb, [ $i, [ File::Spec->rel2abs( $files[ $j - 1 ] ) ] ] );
    }
  }
  ok( !defined( $it->next_comb ) );

}

done_testing();

use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;
use Bio::Grid::Run::SGE::Index;
use File::Compare qw/compare/;

BEGIN { use_ok('Bio::Grid::Run::SGE::Iterator::Consecutive'); }

my $tmp_dir = tempdir( CLEANUP => 1 );
my $idx_file_a = catfile( $tmp_dir, 'a.idx' );
my $idx_file_b = catfile( $tmp_dir, 'b.idx' );
my $idx_a = Bio::Grid::Run::SGE::Index->new( format => 'Dummy', chunk_size => 10 );
$idx_a->create;

my $it_1 = Bio::Grid::Run::SGE::Iterator::Consecutive->new( indices => [$idx_a] );

is( $it_1->num_comb, 3 );

$it_1->start( [0, $it_1->num_comb -1 ]);

my @result;
while ( my $comb = $it_1->next_comb ) {
    push @result, $comb->[0];
}

is( join("", @result), join("",  'a' .. 'z' ) );

$it_1->start( [0, $it_1->num_comb -1 ]);


my $comb = $it_1->next_comb;

is_deeply( $comb, [ join('', 'a' .. 'j') ] );
is($it_1->cur_comb->[0], "abcdefghij");


my $idx_b = Bio::Grid::Run::SGE::Index->new(
    format    => 'General',
    sep       => '^>',
    idx_file  => $idx_file_b,
    writeable => 1,
);
$idx_b->create( ['t/data/test.fa'] );
my $it_2 = Bio::Grid::Run::SGE::Iterator::Consecutive->new( indices => [$idx_b] );

is( $it_2->num_comb, 45 );

$it_2->start( [ 1, 5, 3 ] );

my $range_1_5_3 = catfile($tmp_dir, "range-1-5-3.fa");
open my $range_1_5_3_fh, '>', $range_1_5_3 or die "Can't open filehandle: $!";
while ( my $comb = $it_2->next_comb ) {
    print $range_1_5_3_fh $comb->[0];
}
$range_1_5_3_fh->close;

is( compare( $range_1_5_3, 't/data/Bio-Grid-Run-SGE-Consecutive.range-1-5-3.fa' ), 0, 'range 1,5,3' );

done_testing();

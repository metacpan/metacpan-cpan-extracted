use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;
use Bio::Grid::Run::SGE::Index;
use File::Compare qw/compare/;
use Bio::Grid::Run::SGE::Iterator;
use Math::Combinatorics;

BEGIN { use_ok('Bio::Grid::Run::SGE::Iterator::AllvsAllNoRep'); }

my $tmp_dir = tempdir( CLEANUP => 1 );
my $idx_file_a = catfile( $tmp_dir, 'a.idx' );
my $idx_a = Bio::Grid::Run::SGE::Index->new( format => 'Dummy', idx_file => $idx_file_a );
$idx_a->create;

my $it_1 = Bio::Grid::Run::SGE::Iterator->new( mode => 'AllvsAllNoRep', indices => [$idx_a] );

is( $it_1->num_comb, 325 );

$it_1->start( [0, $it_1->num_comb -1 ]);

my $i = 0;
my @result;
while ( my $comb = $it_1->next_comb ) {
    #diag join " ", @$comb;
    #diag Dumper $comb;
    push @result, $comb->[0];
    $i++;
}
    #die $i;

#is( join("", @result), join("",  'a' .. 'z' ) );

done_testing();


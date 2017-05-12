use warnings;
use Test::More;
use Data::Dumper;

use File::Temp qw/tempdir/;
use File::Compare qw/compare/;
use File::Spec::Functions qw/catfile rel2abs/;

BEGIN { use_ok('Bio::Grid::Run::SGE::Index::Range'); }

my $td = tempdir( CLEANUP => 1 );

my $idx = Bio::Grid::Run::SGE::Index::Range->new(
    'writeable' => 1,
    'idx_file'  => catfile( $td, 'test.idx' ),
);

my @range = (0,6);
$idx->create( \@range );

is($idx->num_elem, 7);

for my $elem_idx ( @range ) {
    my $data = $idx->get_elem($elem_idx);
    is_deeply( $data, [ $elem_idx ],  'elem data test' );
}

done_testing();

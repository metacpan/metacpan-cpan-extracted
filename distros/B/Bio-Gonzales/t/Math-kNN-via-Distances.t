use warnings;
use Data::Dumper;
use Test::More;

BEGIN { use_ok('Bio::Gonzales::Util::Math::kNN::via::Distances'); }

my $d;
sub TEST { $d = $_[0]; }

my $distance_matrix = [ [ 1, ], [ 1, 3 ], [ 5, 10, 11 ], [2, 6, 2, 6] ];

my $groups = [ undef, 'eins', undef, 'zwei' ];
#TESTS
TEST 'basics';
{
    my $knn = Bio::Gonzales::Util::Math::kNN::via::Distances->new(distances => $distance_matrix, groups => $groups);

    is_deeply($knn->calc(1), ['eins', undef, 'zwei', undef],$d);
}

done_testing();

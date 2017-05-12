#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::FastSOM::Torus') };

######
use Storable 'retrieve';

ok( open(FILE, '< t/save_torus_bmu.bin'), 'torus open' );
my ( $bmu_x, $bmu_y ) = <FILE>;

chomp $bmu_x;
chomp $bmu_y;

ok( defined $bmu_x, 'x' );
ok( defined $bmu_y, 'y' );

{
    my $nn = retrieve( 't/save_torus.bin' );

    isa_ok( $nn, 'AI::NeuralNet::FastSOM::Torus', 'retrieve torus' );

    is($nn->{_X}, 5, '_X');
    is($nn->{_Y}, 6, '_Y');
    is($nn->{_Z}, 3, '_Z');

    my ($x,$y) = $nn->bmu([3,2,4]);
    is( $x, $bmu_x, 'stored x' );
    is( $y, $bmu_y, 'stored y' );

    my $m = $nn->map;
    isa_ok( $m, 'ARRAY', 'stored map' );
    isa_ok( $m->[0], 'ARRAY', 'stored array' );
    isa_ok( $m->[0][0], 'ARRAY', 'stored vector' );
    ok( $m->[0][0][0], 'stored scalar' );
}

__END__


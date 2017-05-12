use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::FastSOM::Torus') };

######
use AI::NeuralNet::FastSOM::Utils;
use Storable qw/store/;

{
    my $nn = AI::NeuralNet::FastSOM::Torus->new(
        output_dim => "5x6",
        input_dim  => 3,
    );
    ok( $nn->isa ('AI::NeuralNet::FastSOM::Torus'), 'class' );
    is( $nn->{_X}, 5, 'X' );
    is( $nn->{_Y}, 6, 'Y' );
    is( $nn->{_Z}, 3, 'Z' );
    is( $nn->radius, 2.5, 'radius' );
    is( $nn->output_dim, "5x6", 'output dim' );
}

{
    my $nn = AI::NeuralNet::FastSOM::Torus->new(
        output_dim => "5x6",
        input_dim  => 3,
    );

    ok(
        eq_set(
            $nn->neighbors(1, 0, 0),
            [
                [ 0, 0, '0' ],
                [ 0, 1, '1' ],
                [ 0, 5, '1' ],
                [ 1, 0, '1' ],
                [ 4, 0, '1' ]
            ]
        ),
        'neighbors 4+1'
    );

    ok(
        eq_set(
            $nn->neighbors(1, 3, 2),
            [
                [ 2, 2, '1' ],
                [ 3, 1, '1' ],
                [ 3, 2, '0' ],
                [ 3, 3, '1' ],
                [ 4, 2, '1' ]
            ]
        ),
        'neighbors 4+1'
    );
}

sub _find {
    my $v = shift;
    my $m = shift;

    for my $x ( 0 .. 4 ) {
        for my $y ( 0 .. 5 ) {
            return 1
                if AI::NeuralNet::FastSOM::Utils::vector_distance( $m->[$x]->[$y], $v ) < 0.01;
        }
    }
    return 0;
}

{
    my $nn = AI::NeuralNet::FastSOM::Torus->new(
        output_dim => "5x6",
        input_dim  => 3,
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    for my $v (@vs) {
        ok( _find($v, $nn->map), 'found learned vector '. join (",", @$v) );
    }


    ok( $nn->as_string, 'pretty print' );
    ok( $nn->as_data, 'raw format' );
}

{
    my $nn = AI::NeuralNet::FastSOM::Torus->new(
        output_dim => '5x6',
        input_dim  => 3,
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    my $k = keys %$nn;
    is( $k, 10, 'scalar torus key count' );
    my @k = keys %$nn;
    is( @k, 10, 'array torus key count' );
}

{
    my $nn = AI::NeuralNet::FastSOM::Torus->new(
        output_dim => '5x6',
        input_dim  => 3
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    my ($bmu_x,$bmu_y) = $nn->bmu([3,2,4]);

    ok( open(FILE, '> t/save_torus_bmu.bin'), 'torus save' );
    print FILE "$bmu_x\n$bmu_y\n";
    close FILE;

    store( $nn, 't/save_torus.bin' );
}

__END__


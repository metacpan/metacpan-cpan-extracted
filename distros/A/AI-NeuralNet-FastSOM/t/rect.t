#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::FastSOM::Rect') };

######
use AI::NeuralNet::FastSOM::Utils;
use Storable qw/store/;

{
    my $nn = AI::NeuralNet::FastSOM::Rect->new(
        output_dim => '5x6',
        input_dim  => 3
    );

    ok( $nn->isa( 'AI::NeuralNet::FastSOM::Rect' ), 'rect class' );

    my $nn2 = $nn;
    my $nn3 = $nn2;
    is( $nn, $nn3, 'rect eq' );

    my $m1 = $nn->map;
    isa_ok( $m1, 'ARRAY', 'map array' );

    my $m2 = $m1;
    my $m3 = $nn2->map;
    my $m4 = $m3;
    is( $m2, $m4, 'map eq' );

    my $a = $m1->[0];
    isa_ok( $a, 'ARRAY', 'array array' );
    ok( $a != $m1, 'array unique' );

    my $a2 = $m4->[0];
    is( $a, $a2, 'array eq' );

    my $v = $a->[0];
    isa_ok( $v, 'ARRAY', 'vector array' );
    ok( $v != $a, 'vector unique' );

    my $v2 = $nn3->map->[0]->[0];
    is( $v, $v2, 'vector eq' );

    my $v3 = $nn2->map->[0][0];
    is( $v, $v3, 'vector shorter' );

    my $m = $nn->map;
    $m->[0][0][0] = 3.245;
    is( $m->[0][0][0], 3.245, 'element set' );
    $m->[0][0][0] = 1.25;
    is( $m->[0][0][0], 1.25, 'element reset' );
    $m->[0][0][1] = 4.8;
    is( $m->[0][0][1], 4.8, 'element set z' );
    $m->[0][0][1] = 2.6;
    is( $m->[0][0][1], 2.6, 'element reset z' );
    $m->[0][1][0] = 8.9;
    is( $m->[0][1][0], 8.9, 'element set y' );
    $m->[0][1][0] = 1.2;
    is( $m->[0][1][0], 1.2, 'element reset y' );
    $m->[1][0][0] = 5.4;
    is( $m->[1][0][0], 5.4, 'element set z' );
    $m->[1][0][0] = 3.23;
    is( $m->[1][0][0], 3.23, 'element reset z');

    $m->[4][5][2] = 2.29;
    is( $m->[4][5][2], 2.29, 'last element set' );
    is( $m->[-1][5][2], 2.29, 'negative x' );
    is( $m->[4][-1][2], 2.29, 'negative y' );
    is( $m->[4][5][-1], 2.29, 'negative z' );
    is( $m->[-1][-1][-1], 2.29, 'negative all' );
}

{
    my $nn = AI::NeuralNet::FastSOM::Rect->new(
        output_dim => '5x6',
        input_dim  => 3
    );
    ok ($nn->isa ('AI::NeuralNet::FastSOM::Rect'), 'class');
    is ($nn->{_X}, 5, 'X');
    is ($nn->{_Y}, 6, 'Y');
    is ($nn->{_Z}, 3, 'Z');
    is ($nn->radius, 2.5, 'radius');
    is ($nn->output_dim, "5x6", 'output dim');
}

sub _find {
    my $v = shift;
    my $m = shift;

    for my $x ( 0 .. 4 ) {
        for my $y ( 0 .. 5 ) {
            my $rv = AI::NeuralNet::FastSOM::Utils::vector_distance($m->[$x]->[$y], $v);
            return 1 if $rv < 0.01;
        }
    }
    return 0;
}

{
    my $nn = new AI::NeuralNet::FastSOM::Rect(
        output_dim => "5x6",
        input_dim  => 3
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    for my $v (@vs) {
        ok(_find($v,$nn->map),'found learned vector '.join(",", @$v));
    }

    ok ($nn->as_string, 'pretty print');
    ok ($nn->as_data, 'raw format');
}

{
    my $nn = new AI::NeuralNet::FastSOM::Rect (output_dim => "5x6",
                       input_dim  => 3);
    $nn->initialize;

    for my $x (0 .. 5 -1) {
        for my $y (0 .. 6 -1 ) {
            ok ( (!grep { $_ > 0.5 || $_ < -0.5 } @{ $nn->value ( $x, $y ) }) , "$x, $y: random vectors in [-0.5, 0.5]");
        }
    }
}

{
    my $nn = new AI::NeuralNet::FastSOM::Rect(
        output_dim => "5x6",
        input_dim  => 3
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    my $k = keys %$nn;
    is( $k, 10, 'scalar rect key count' );
    my @k = keys %$nn;
    is( @k, 10, 'array rect key count' );
}

{
    my $nn = AI::NeuralNet::FastSOM::Rect->new(
        output_dim => '5x6',
        input_dim  => 3
    );
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train(400, @vs);

    my ($bmu_x,$bmu_y) = $nn->bmu([3,2,4]);

    ok( open(FILE, '> t/save_rect_bmu.bin'), 'rect save' );
    print FILE "$bmu_x\n$bmu_y\n";
    close FILE;

    store( $nn, 't/save_rect.bin' );
}

__END__


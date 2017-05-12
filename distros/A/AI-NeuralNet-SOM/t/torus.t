#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::SOM::Torus') };

######
use Data::Dumper;

{
    my $nn = new AI::NeuralNet::SOM::Torus (output_dim => "5x6",
					    input_dim  => 3);
    ok ($nn->isa ('AI::NeuralNet::SOM::Torus'), 'class');
    is ($nn->{_X}, 5, 'X');
    is ($nn->{_Y}, 6, 'Y');
    is ($nn->{_Z}, 3, 'Z');
    is ($nn->radius, 2.5, 'radius');
    is ($nn->output_dim, "5x6", 'output dim');
}

{
    my $nn = new AI::NeuralNet::SOM::Torus (output_dim => "5x6",
					    input_dim  => 3);

    ok (eq_set ( $nn->neighbors (1, 0, 0),
		   [
		    [ 0, 0, '0' ],
		    [ 0, 1, '1' ],
		    [ 0, 5, '1' ],
		    [ 1, 0, '1' ],
		    [ 4, 0, '1' ]
		   ]), 'neighbors 4+1');

    ok (eq_set ( $nn->neighbors (1, 3, 2),
		   [
		    [ 2, 2, '1' ],
		    [ 3, 1, '1' ],
		    [ 3, 2, '0' ],
		    [ 3, 3, '1' ],
		    [ 4, 2, '1' ]
		   ]), 'neighbors 4+1');
}

{
    my $nn = new AI::NeuralNet::SOM::Torus (output_dim => "5x6",
					    input_dim  => 3);
    $nn->initialize;
#    print Dumper $nn;
#    exit;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);
    $nn->train (400, @vs);

    foreach my $v (@vs) {
	ok (_find ($v, $nn->map), 'found learned vector '. join (",", @$v));
    }

sub _find {
    my $v = shift;
    my $m = shift;

    use AI::NeuralNet::SOM::Utils;
    foreach my $x ( 0 .. 4 ) {
	foreach my $y ( 0 .. 5 ) {
	    return 1 if AI::NeuralNet::SOM::Utils::vector_distance ($m->[$x]->[$y], $v) < 0.01;
	}
    }
    return 0;
}


    ok ($nn->as_string, 'pretty print');
    ok ($nn->as_data, 'raw format');

#    print $nn->as_string;
}

__END__

# randomized pick
    @vectors = ...;
my $get = sub {
    return @vectors [ int (rand (scalar @vectors) ) ];
    
}
$nn->train ($get);

# take exactly 500, round robin, in order
our $i = 0;
my $get = sub {
    return undef unless $i < 500;
return @vectors [ $i++ % scalar @vectors ];
}

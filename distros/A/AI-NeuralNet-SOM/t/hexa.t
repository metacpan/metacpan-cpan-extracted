#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::SOM::Hexa') };

######

use Data::Dumper;

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 6,
					   input_dim  => 3);
    ok ($nn->isa ('AI::NeuralNet::SOM::Hexa'), 'class');
    is ($nn->{_R}, 3, 'R');
    is ($nn->radius, 3, 'radius');
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 2,
					   input_dim  => 3);
    $nn->initialize ( [ 0, 0, 1 ], [ 0, 1, 0 ] );

    my $d = $nn->diameter;
    for my $x (0 .. $d-1) {
	for my $y (0 .. $d-1) {
	    ok (eq_array ($nn->{map}->[$x]->[$y], 
			  $y == 0 ? [ 0, 0, 1 ] : [ 0, 1, 0 ]), 'value init');
	}
    }
#    warn Dumper $nn;
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 2,
					   input_dim  => 3);
    $nn->initialize;

    foreach my $x (0 .. $nn->diameter -1) {
	foreach my $y (0 .. $nn->diameter -1 ) {
	    ok ( (!grep { $_ > 0.5 || $_ < -0.5 } @{ $nn->value ( $x, $y ) }) , "$x, $y: random vectors in [-0.5, 0.5]");
	}
    }
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 2,
					   input_dim  => 3);
    $nn->initialize ( [ 0, 0, 1 ] );

    ok (eq_array ($nn->bmu ([ 1, 1, 1 ]),
		  [ 1, 1, 0 ]), 'bmu');
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 6,
					   input_dim  => 3);
#    warn Dumper $nn;
    ok (eq_array ( $nn->neighbors (1, 3, 2),
		   [
		    [2, 1, 1 ],
		    [2, 2, 1 ],
		    [3, 1, 1 ],
		    [3,	2, 0 ],
		    [3,	3, 1 ],
		    [4,	2, 1 ],
		    [4,	3, 1 ]
		   ]), 'neighbors 6+1');

    ok (eq_array ( $nn->neighbors (1, 0, 0),
		   [
		    [0, 0, 0 ],
		    [0, 1, 1 ],
		    [1, 0, 1 ],
		    [1,	1, 1 ],
		   ]), 'neighbors 3+1');

    ok (eq_array ( $nn->neighbors (0, 3, 3),
		   [
		    [3, 3, 0 ],
		   ]), 'neighbors 0+1');
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 3,
					   input_dim  => 3,
					   sigma0     => 4); # make change network-wide
    $nn->initialize ( [ 0, -1, 1 ] );
    $nn->train (100, [ 1, 1, 1 ]); 

#    warn Dumper $nn;

    foreach my $x (0 .. $nn->diameter -1) {
	foreach my $y (0 .. $nn->diameter -1 ) {
	    ok ( (! grep { $_ < 0.9 } @{ $nn->value ( $x, $y ) }) , "$x, $y: vector above 0.9");
	}
    }
}

{
    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 3,
					   input_dim  => 3);
    $nn->initialize ( [ 0, -1, -1 ] );
    $nn->train (100, [ 1, 1, 1 ]); 

    my ($x, $y) = $nn->bmu ([ 1, 1, 1 ]) ;
    ok (eq_array ([ $x, $y ],
		  [ 0, 0 ]), 'bmu after training');

#    warn Dumper $nn;
}
__END__


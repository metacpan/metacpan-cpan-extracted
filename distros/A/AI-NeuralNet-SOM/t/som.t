#########################

# Change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('AI::NeuralNet::SOM') };

######
use Data::Dumper;

{
    use AI::NeuralNet::SOM::Rect;    # any non-abstract subclass should do
    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
					   input_dim  => 3,
					   );
    $nn->value ( 1, 1, [ 1, 1, 1 ] );
    ok (eq_array ($nn->value ( 1, 1),
		  [ 1, 1, 1 ]), 'value set/get');
    $nn->label ( 1, 1, 'rumsti' );
    is ($nn->label ( 1, 1), 'rumsti', 'label set/get');

    is ($nn->label ( 1, 0), undef, 'label set/get');
}

{
    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
					   input_dim  => 3);
    $nn->initialize;

    my @vs = ([ 3, 2, 4 ], [ -1, -1, -1 ], [ 0, 4, -3]);

    my $me = $nn->mean_error (@vs);
    for (1 .. 40) {
	$nn->train (50, @vs);
	ok ($me >= $nn->mean_error (@vs), 'mean error getting smaller');
	$me = $nn->mean_error (@vs);
#	warn $me;
    }

    foreach (1..3) {
	my @mes = $nn->train (20, @vs);
	is (scalar @mes, 3 * 20, 'errors while training, nr');
	ok ((!grep { $_ > 10 * $me } @mes), 'errors while training, none significantly bigger');
    }
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

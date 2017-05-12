=begin
    
    File:	examples/ex_synop.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

        This is the synopsis from the POD for AI::NeuralNet::BackProp.
		
=cut

	use AI::NeuralNet::Mesh;
	
	# Create a new network with 1 layer, 5 inputs, and 5 outputs.
	my $net = new AI::NeuralNet::Mesh(1,5,5);
	
	# Add a small amount of randomness to the network
	$net->random(0.001);

	# Demonstrate a simple learn() call
	my @inputs = ( 0,0,1,1,1 );
	my @ouputs = ( 1,0,1,0,1 );
	
	print $net->learn(\@inputs, \@outputs),"\n";

	# Create a data set to learn
	my @set = (
		[ 2,2,3,4,1 ], [ 1,1,1,1,1 ],
		[ 1,1,1,1,1 ], [ 0,0,0,0,0 ],
		[ 1,1,1,0,0 ], [ 0,0,0,1,1 ]	
	);
	
	# Demo learn_set()
	my $f = $net->learn_set(\@set);
	print "Forgetfulness: $f unit\n";
	
	# Crunch a bunch of strings and return array refs
	my $phrase1 = $net->crunch("I love neural networks!");
	my $phrase2 = $net->crunch("Jay Lenno is wierd.");
	my $phrase3 = $net->crunch("The rain in spain...");
	my $phrase4 = $net->crunch("Tired of word crunching yet?");

	# Make a data set from the array refs
	my @phrases = (
		$phrase1, $phrase2,
		$phrase3, $phrase4
	);

	# Learn the data set	
	$net->learn_set(\@phrases);
	
	# Run a test phrase through the network
	my $test_phrase = $net->crunch("I love neural networking!");
	my $result = $net->run($test_phrase);
	
	# Get this, it prints "Jay Leno is  networking!" ...  LOL!
	print $net->uncrunch($result),"\n";

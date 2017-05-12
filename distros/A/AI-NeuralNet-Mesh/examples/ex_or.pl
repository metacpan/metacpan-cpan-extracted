=begin
    
    File:	examples/ex_and.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates a simple OR gate.    
		This is an intersting function of the network, as it functions
		as an OR gate with no learning and only a sigmoid transfer function
		on the output node.

=cut

	use AI::neuralNet::Mesh;
	
	# Uses 1 layer and 2 nodes per layer, with one output node
	my $net = new AI::NeuralNet::Mesh(1,2,1);
	
	# Example of alternate ways to set activation and thresholds
	$net->activation(1,sigmoid);
	$net->threshold( 1,0.5);
	
	if(!$net->load('or.mesh')) {
		$net->learn_set([	
			[1,1], [1],
			[1,0], [1],
			[0,1], [1],
			[0,0], [0],
		]);
		$net->save('or.mesh');
	}

	print "Learning complete.\n";
	print "Testing with a gate value of (0,0):",$net->run([0,0])->[0],"\n";
	print "Testing with a gate value of (0,1):",$net->run([0,1])->[0],"\n";
	print "Testing with a gate value of (1,0):",$net->run([1,0])->[0],"\n";
	print "Testing with a gate value of (1,1):",$net->run([1,1])->[0],"\n";
	
	
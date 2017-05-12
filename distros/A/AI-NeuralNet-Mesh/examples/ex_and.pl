=begin
    
    File:	examples/ex_and.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates a simple AND gate.
		Included is example of the hash construction form of the new() method.

=cut

	use AI::neuralNet::Mesh;
	
	# Uses 1 layer and 2 nodes per layer, with one output node
	my $net = new AI::NeuralNet::Mesh([
		{
			nodes		=>	2,    		# input layer, 2 nodes
			activation  =>	linear		# linear transfer function
		},
		{
			nodes		=>	1,			# output layer, 1 node
			activation	=>	sigmoid,	# sigmoid transfer function, (0/1)
			threshold	=>	0.75		# set threshold for sigmoid fn to 0.75
		}
	]);
	
	if(!$net->load('and.mesh')) {
		$net->learn_set([	
			[1,1], [1],
			[1,0], [0],
			[0,1], [0],
			[0,0], [0],
		]);
		$net->save('and.mesh');
	}

	print "Learning complete.\n";
	print "Testing with a gate value of (0,0):",$net->run([0,0])->[0],"\n";
	print "Testing with a gate value of (0,1):",$net->run([0,1])->[0],"\n";
	print "Testing with a gate value of (1,0):",$net->run([1,0])->[0],"\n";
	print "Testing with a gate value of (1,1):",$net->run([1,1])->[0],"\n";
	
	
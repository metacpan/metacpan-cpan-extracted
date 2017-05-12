=begin
    
    File:	examples/ex_bmp2.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates the ability of a neural net 
		to generalize and predict what the correct 
		result is for inputs that it has never seen before.
				
		This teaches a network to recognize a 5x7 bitmap of 
		the letter "J" then it presents the network with a 
		corrupted "J" and displays the results of the networks 
		output.

=cut

    use AI::NeuralNet::Mesh;

	# Create a new network with 2 layers and 35 neurons in each layer.
    my $net = new AI::NeuralNet::Mesh(1,35,1);
	
	# Debug level of 4 gives JUST learn loop iteteration benchmark and comparrison data 
	# as learning progresses.
	$net->debug(4);
	
	# Create our model input
	my @map	=	(1,1,1,1,1,
				 0,0,1,0,0,
				 0,0,1,0,0,
				 0,0,1,0,0,
				 1,0,1,0,0,
				 1,0,1,0,0,
				 1,1,1,0,0);
				 
	
	print "\nLearning started...\n";
	
	print $net->learn(\@map,'J');
	
	print "Learning done.\n";
		
	# Build a test map 
	my @tmp	=	(0,0,1,1,1,
				 1,1,1,0,0,
				 0,0,0,1,0,
				 0,0,0,1,0,
				 0,0,0,1,0,                                          
				 0,0,0,0,0,
				 0,1,1,0,0);
	
	# Display test map
	print "\nTest map:\n";
	$net->join_cols(\@tmp,5,'');
	
	print "Running test...\n";
		                    
	# Run the actual test and get network output
	print "Result: ",$net->run_uc(\@tmp),"\n";
	
	print "Test run complete.\n";
	
	

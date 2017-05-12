=begin

	File:   examples/ex_dow.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
    Desc:
		
		This demonstrates DOW Avg. predicting using the 
		AI::NeuralNet::Mesh module.

=cut

    use AI::NeuralNet::Mesh;
	use Benchmark;

	# Create a new net with 5 layes, 9 inputs, and 1 output
        my $net = AI::NeuralNet::Mesh->new(2,9,1);
	
	# Disable debugging
        $net->debug(2);
	
	# Create datasets.
	#	Note that these are ficticious values shown for illustration purposes
	#	only.  In the example, CPI is a certain month's consumer price
	#	index, CPI-1 is the index one month before, CPI-3 is the the index 3
	#	months before, etc.

	my @data = ( 
		#	Mo  CPI  CPI-1 CPI-3 	Oil  Oil-1 Oil-3    Dow   Dow-1 Dow-3   Dow Ave (output)
		[	1, 	229, 220,  146, 	20.0, 21.9, 19.5, 	2645, 2652, 2597], 	[	2647  ],
		[	2, 	235, 226,  155, 	19.8, 20.0, 18.3, 	2633, 2645, 2585], 	[	2637  ],
		[	3, 	244, 235,  164, 	19.6, 19.8, 18.1, 	2627, 2633, 2579], 	[	2630  ],
		[	4, 	261, 244,  181, 	19.6, 19.6, 18.1, 	2611, 2627, 2563], 	[	2620  ],
		[	5, 	276, 261,  196, 	19.5, 19.6, 18.0, 	2630, 2611, 2582], 	[	2638  ],
		[	6, 	287, 276,  207, 	19.5, 19.5, 18.0, 	2637, 2630, 2589], 	[	2635  ],
		[	7, 	296, 287,  212, 	19.3, 19.5, 17.8, 	2640, 2637, 2592], 	[	2641  ] 		
	);
    
    
	# If we havnt saved the net already, do the learning
        if(!$net->load('DOW.mesh')) {
		print "\nLearning started...\n";
		
		# Make it learn the whole dataset $top times
		my @list;
		my $top=1;
		for my $a (0..$top) {
			my $t1=new Benchmark;
			print "\n\nOuter Loop: $a\n";
			
			# Test fogetfullness
			my $f = $net->learn_set(\@data,	inc		=>	0.2,	
											max		=>	2000,
											error	=>	-1);
			
			# Print it 
			print "\n\nForgetfullness: $f%\n";

			# Save net to disk				
            $net->save('DOW.mesh');
            
			my $t2=new Benchmark;
			my $td=timediff($t2,$t1);
			print "\nLoop $a took ",timestr($td),"\n";
		}
	}
                                                                          
	# Run a prediction using fake data
	#			Month	CPI  CPI-1 CPI-3 	Oil  Oil-1 Oil-3    Dow   Dow-1 Dow-3    
	my @set=(	10,		352, 309,  203, 	18.3, 18.7, 16.1, 	2592, 2641, 2651	  ); 
	
	# Dow Ave (output)	
	my $fb=$net->run(\@set)->[0];
	
	# Print output
	print "\nTest Factors: (",join(',',@set),")\n";
	print "DOW Prediction for Month #11: $fb\n";
	

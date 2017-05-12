=begin

	File:   examples/ex_bmp.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc:
	
		This demonstrates simple classification of 6x6 bitmaps.

=cut

	use AI::NeuralNet::Mesh;
	use Benchmark;

	# Set resolution
	my $xres=5;
	my $yres=5;
	
	# Create a new net with 3 layes, $xres*$yres inputs, and 1 output
	my $net = AI::NeuralNet::Mesh->new(1,$xres*$yres,1);
	
	# Enable debugging
	$net->debug(4);
	
	# Create datasets.
	my @data = ( 
		[	0,1,1,0,0,
			0,0,1,0,0,
			0,0,1,0,0,
			0,0,1,0,0,
			0,1,1,1,2	],		[	1	],
		
		[	1,1,1,0,0,
			0,0,0,1,0,
			0,1,1,1,0,
			1,0,0,0,0,
			1,1,1,1,2	],		[	2	],
		
		[	0,1,1,1,0,
			1,0,0,0,0,
			1,1,1,0,0,
			1,0,0,0,0,
			0,1,1,1,2	],		[	3	],
		
		[	1,0,0,1,0,
			1,0,0,1,0,
			1,1,1,1,0,
			0,0,0,1,0,
			0,0,0,1,2	],		[	4	],
		
		
		[	1,1,1,1,0,
			1,0,0,0,0,
			1,1,1,1,0,
			0,0,0,1,0,
			1,1,1,1,2	],		[	5	],
		
	);
    
    
	# If we havnt saved the net already, do the learning
	if(!$net->load('images.mesh')) {
		print "\nLearning started...\n";
		
		# Make it learn the whole dataset $top times
		my @list;
		my $top=3;
		for my $a (0..$top) {
			my $t1=new Benchmark;
			print "\n\nOuter Loop: $a\n";
			
			# Test fogetfullness
			my $f = $net->learn_set(\@data,	inc => 0.1);
			
			# Print it 
			print "\n\nForgetfullness: $f%\n";

			# Save net to disk				
			$net->save('images.mesh');

			my $t2=new Benchmark;
			my $td=timediff($t0,$t1);
			print "\nLoop $a took ",timestr($td),"\n";
		}
	}
                                                                          
	my @set=(		0,1,1,1,0,
					1,0,0,0,0,
					1,1,1,0,0,
					1,0,0,0,0,
					0,1,1,1,2		);
		
	
	# Image number
	my $fb=$net->run(\@set)->[0];
	
	
	# Print output
	print "\nTest Map: \n";
	$net->join_cols(\@set,5);
	print "Image number matched: $fb\n";
	



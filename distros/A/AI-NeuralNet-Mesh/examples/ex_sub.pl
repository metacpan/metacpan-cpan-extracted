=begin
    
    File:	examples/ex_sub.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates the ability of a neural net to generalize and predict what the correct
		result is for inputs that it has never seen before.
		
		This teaches a network to subtract 6 sets of numbers, then it asks the user for 
		two numbers to subtract and then it displays the results of the user's input.

=cut

	use AI::NeuralNet::Mesh;
	
	my $subtract = new AI::NeuralNet::Mesh(2,2,1);
	
	if(!$subtract->load('sub.mesh')) {
		$subtract->learn_set([	
			[ 1,   1   ], [ 0      ] ,
			[ 2,   1   ], [ 1      ],
			[ 10,  5   ], [ 5      ],
			[ 20,  10  ], [ 10     ],
			[ 100, 50  ], [ 50     ],
			[ 500, 200 ], [ 300    ],
		]);
		$subtract->save('sub.mesh');
	}
		
	print "Enter first number to subtract  : "; chomp(my $a = <>);
	print "Enter second number to subtract : "; chomp(my $b = <>);
	
	print "Result: ",$subtract->run([$a,$b])->[0],"\n";
	
	
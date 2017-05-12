=begin
    
    File:	examples/ex_mult.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates the ability of a neural net to generalize and predict what the correct
		result is for inputs that it has never seen before.
		
		This teaches a network to multiply 6 sets of numbers, then it asks the user for 
		two numbers to multiply and then it displays the results of the user's input.

=cut

	use AI::NeuralNet::Mesh;
	
	my $multiply = new AI::NeuralNet::Mesh(2,2,1);
	
	if(!$multiply->load('mult.mesh')) {
		$multiply->learn_set([	
			[ 1,   1   ], [ 1      ] ,
			[ 2,   1   ], [ 2      ],
			[ 2,   2   ], [ 4      ],
			[ 2,   4   ], [ 8      ],
			[ 2,   8   ], [ 16     ],
			[ 9,   9   ], [ 81     ],
			[ 10,  5   ], [ 50     ],
			[ 20,  10  ], [ 200    ],
			[ 100, 50  ], [ 5000   ],
		]);
		$multiply->save('mult.mesh');
	}
		
	print "Enter first number to multiply  : "; chomp(my $a = <>);
	print "Enter second number to multiply : "; chomp(my $b = <>);
	
	print "Result: ",$multiply->run([$a,$b])->[0],"\n";
	
	
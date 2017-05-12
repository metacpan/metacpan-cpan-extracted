=begin

	File:   examples/ex_crunch.pl
	Author: Josiah Bryan, jdb@wcoil.com
	Desc:
	
	    This demonstrates the crunch() and uncrunch() methods.

=cut


	use AI::NeuralNet::BackProp;
	
	my $net = AI::NeuralNet::BackProp->new(2,3);
	
	# Here crunch is good for storing sentance crunches
	my $bad  = $net->crunch("That's Junk Food!");
	my $good = $net->crunch("Good, Healthy Food.");
	
	for (0..3) {
		# learn() can use strings in two ways: As an array ref from crunch(), or
		# directly as a string, which it then will crunch internally.
		$net->learn($net->crunch("I love chips."),  $bad);
		$net->learn($net->crunch("I love apples."), $good);
		$net->learn("I love pop.",    				$bad);
		$net->learn("I love oranges.",				$good);
	}
	
	# run() automatically crunches the string (run_uc() uses run() internally) and
	# run_uc() automatically uncrunches the results.
	print $net->run_uc("I love corn.");

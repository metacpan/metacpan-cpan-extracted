=begin

	File:   examples/ex_crunch.pl
	Author: Josiah Bryan, jdb@wcoil.com
	Desc:
	
	    This demonstrates the crunch() and uncrunch() methods.

=cut


	use AI::NeuralNet::Mesh;
	
	my $net = AI::NeuralNet::Mesh->new(2,3);
	
	# Here crunch is good for storing sentance crunches
	my $bad  = $net->crunch("That's Junk Food!");
	my $good = $net->crunch("Good, Healthy Food.");
	
	my $set  = [
		"I love chips.",	$bad,
		"I love apples.",	$good,
		"I love pop.",		$bad,
		"I love oranges.",	$good
	];
	
	#$net->debug(4);
	for (0..2) {
		my $f = $net->learn_set($set);
		print "Forgotten: $f%\n";
	}
	
	# run() automatically crunches the string (run_uc() uses run() internally) and
	# run_uc() automatically uncrunches the results.
	print $net->run_uc("I love pop-tarts.");

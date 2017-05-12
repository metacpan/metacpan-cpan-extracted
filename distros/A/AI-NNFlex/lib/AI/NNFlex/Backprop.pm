##########################################################
# AI::NNFlex::Backprop
##########################################################
# Backprop with simple (non adaptive) momentum
##########################################################
# Versions
# ========
#
# 1.0	20050121	CColbourn	New module
# 1.1	20050201	CColbourn	Added call to activation
#					function slope instead
#					of hardcoded 1-y*y
#
# 1.2	20050218	CColbourn	Mod'd to change weight
#					indexing to array for
#					nnflex 0.16
#
# 1.3	20050307	CColbourn	packaged as a subclass of NNFLex
#
# 1.4	20050313	CColbourn	modified the slope function call
#					to avoid using eval
#
# 1.5	20050314	CColbourn	applied fahlman constant
# 					Renamed Backprop.pm, see CHANGES
#
##########################################################
# ToDo
# ----
#
#
###########################################################
#

package AI::NNFlex::Backprop;
use AI::NNFlex;
use AI::NNFlex::Feedforward;
use base qw(AI::NNFlex::Feedforward AI::NNFlex);
use strict;


sub calc_error
{
	my $network = shift;

	my $outputPatternRef = shift;
	my @outputPattern = @$outputPatternRef;

	my @debug = @{$network->{'debug'}};

	if (scalar @debug > 0)
	{$network->dbug ("Output pattern @outputPattern received by Backprop",4);}


	my $outputLayer = $network->{'layers'}->[-1]->{'nodes'};

	if (scalar @$outputLayer != scalar @outputPattern)
	{	
		$network->dbug ("Wrong number of output values, net has ".scalar @$outputLayer." nodes",0);
		return 0;
	}

	# Now calculate the error
	my $counter=0;
	foreach (@$outputLayer)
	{	
		my $value = $_->{'activation'} - $outputPattern[$counter];


		if ($_->{'errorfunction'})
		{
			my $errorfunction = $_->{'errorfunction'};
			$value = $network->$errorfunction($value);
		}
		
		$_->{'error'} = $value;
		$counter++;
		if (scalar @debug > 0)
		{$network->dbug ("Error on output node $_ = ".$_->{'error'},4);}
	}


}


########################################################
# AI::NNFlex::Backprop::learn
########################################################
sub learn
{

	my $network = shift;

	my $outputPatternRef = shift;

	# if this is an incorrect dataset call translate it
	if ($outputPatternRef =~/Dataset/)
	{
		return ($outputPatternRef->learn($network))
	}


	# Set a default value on the Fahlman constant
	if (!$network->{'fahlmanconstant'})
	{
		$network->{'fahlmanconstant'} = 0.1;
	}

	my @outputPattern = @$outputPatternRef;

	$network->calc_error($outputPatternRef);

	#calculate & apply dWs
	$network->hiddenToOutput;
	if (scalar @{$network->{'layers'}} > 2) 
	{
		$network->hiddenOrInputToHidden;
	}

	# calculate network sqErr
	my $Err = $network->RMSErr($outputPatternRef);
	return $Err;	
}


#########################################################
# AI::NNFlex::Backprop::hiddenToOutput
#########################################################
sub hiddenToOutput
{
	my $network = shift;

	my @debug = @{$network->{'debug'}};

	my $outputLayer = $network->{'layers'}->[-1]->{'nodes'};

	foreach my $node (@$outputLayer)
	{
		my $connectedNodeCounter=0;
		foreach my $connectedNode (@{$node->{'connectedNodesWest'}->{'nodes'}})
		{
			my $momentum = 0;
			if ($network->{'momentum'})
			{

				if ($node->{'connectedNodesWest'}->{'lastdelta'}->[$connectedNodeCounter])
				{
					$momentum = ($network->{'momentum'})*($node->{'connectedNodesWest'}->{'lastdelta'}->[$connectedNodeCounter]);
				}
			}
			if (scalar @debug > 0)
			{$network->dbug("Learning rate is ".$network->{'learningrate'},4);}
			my $deltaW = (($network->{'learningrate'}) * ($node->{'error'}) * ($connectedNode->{'activation'}));
			$deltaW = $deltaW+$momentum;
			$node->{'connectedNodesWest'}->{'lastdelta'}->[$connectedNodeCounter] = $deltaW;
			
			if (scalar @debug > 0)
			{$network->dbug("Applying delta $deltaW on hiddenToOutput $connectedNode to $node",4);}
			# 
			$node->{'connectedNodesWest'}->{'weights'}->[$connectedNodeCounter] -= $deltaW;
			$connectedNodeCounter++;
		}
			
	}
}

######################################################
# AI::NNFlex::Backprop::hiddenOrInputToHidden
######################################################
sub hiddenOrInputToHidden
{

	my $network = shift;

	my @layers = @{$network->{'layers'}};

	my @debug = @{$network->{'debug'}};

	# remove the last element (The output layer) from the stack
	# because we've already calculated dW on that
	pop @layers;

	if (scalar @debug > 0)
	{$network->dbug("Starting Backprop of error on ".scalar @layers." hidden layers",4);}

	foreach my $layer (reverse @layers)
	{
		foreach my $node (@{$layer->{'nodes'}})
		{
			my $connectedNodeCounter=0;
			if (!$node->{'connectedNodesWest'}) {last}

			my $nodeError;
			foreach my $connectedNode (@{$node->{'connectedNodesEast'}->{'nodes'}})
			{
				$nodeError += ($connectedNode->{'error'}) * ($connectedNode->{'connectedNodesWest'}->{'weights'}->[$connectedNodeCounter]);
				$connectedNodeCounter++;
			}

			if (scalar @debug > 0)
			{$network->dbug("Hidden node $node error = $nodeError",4);}

			# Apply error function
			if ($node->{'errorfunction'})
			{
				my $functioncall = $node->{'errorfunction'};
				$nodeError = $network->$functioncall($nodeError);
			}

			$node->{'error'} = $nodeError;


			# update the weights from nodes inputting to here
			$connectedNodeCounter=0;
			foreach my $westNodes (@{$node->{'connectedNodesWest'}->{'nodes'}})
			{
				
				my $momentum = 0;
				if ($network->{'momentum'})
				{
					if($node->{'connectedNodesWest'}->{'lastdelta'}->{$westNodes})
					{
						$momentum = ($network->{'momentum'})*($node->{'connectedNodesWest'}->{'lastdelta'}->{$westNodes});
					}
				}

				# get the slope from the activation function component
				my $value = $node->{'activation'};

				my $functionSlope = $node->{'activationfunction'}."_slope";
				$value = $network->$functionSlope($value);

				# Add the Fahlman constant
				$value += $network->{'fahlmanconstant'};

				$value = $value * $node->{'error'} * $network->{'learningrate'} * $westNodes->{'activation'};

				
				my $dW = $value;
				$dW = $dW + $momentum;
				if (scalar @debug > 0)
				{$network->dbug("Applying deltaW $dW to inputToHidden connection from $westNodes to $node",4);}

				$node->{'connectedNodesWest'}->{'lastdelta'}->{$westNodes} = $dW;

				$node->{'connectedNodesWest'}->{'weights'}->[$connectedNodeCounter] -= $dW;
				if (scalar @debug > 0)
				{$network->dbug("Weight now ".$node->{'connectedNodesWest'}->{'weights'}->[$connectedNodeCounter],4);}
				$connectedNodeCounter++;

			}	


		}
	}
								
				

}

#########################################################
# AI::NNFlex::Backprop::RMSErr
#########################################################
sub RMSErr
{
	my $network = shift;

	my $outputPatternRef = shift;
	my @outputPattern = @$outputPatternRef;

	my @debug = @{$network->{'debug'}};

	my $sqrErr;

	my $outputLayer = $network->{'layers'}->[-1]->{'nodes'};

	if (scalar @$outputLayer != scalar @outputPattern)
	{	
		$network->dbug("Wrong number of output values, net has ".scalar @$outputLayer." nodes",0);
		return 0;
	}

	# Now calculate the error
	my $counter=0;
	foreach (@$outputLayer)
	{	
		my $value = $_->{'activation'} - $outputPattern[$counter];

		$sqrErr += $value *$value;
		$counter++;
		if (scalar @debug > 0)
		{$network->dbug("Error on output node $_ = ".$_->{'error'},4);}
	}

	my $error = sqrt($sqrErr);

	return $error;
}

1;

=pod

=head1 NAME

AI::NNFlex::Backprop - a fast, pure perl backprop Neural Net simulator

=head1 SYNOPSIS

 use AI::NNFlex::Backprop;

 my $network = AI::NNFlex::Backprop->new(config parameter=>value);

 $network->add_layer(nodes=>x,activationfunction=>'function');

 $network->init(); 



 use AI::NNFlex::Dataset;

 my $dataset = AI::NNFlex::Dataset->new([
			[INPUTARRAY],[TARGETOUTPUT],
			[INPUTARRAY],[TARGETOUTPUT]]);

 my $sqrError = 10;

 while ($sqrError >0.01)

 {

	$sqrError = $dataset->learn($network);

 }

 $network->lesion({'nodes'=>PROBABILITY,'connections'=>PROBABILITY});

 $network->dump_state(filename=>'badgers.wts');

 $network->load_state(filename=>'badgers.wts');

 my $outputsRef = $dataset->run($network);

 my $outputsRef = $network->output(layer=>2,round=>1);

=head1 DESCRIPTION

AI::NNFlex::Backprop is a class to generate feedforward, backpropagation neural nets. It inherits various constructs from AI::NNFlex & AI::NNFlex::Feedforward, but is documented here as a standalone.

The code should be simple enough to use for teaching purposes, but a simpler implementation of a simple backprop network is included in the example file bp.pl. This is derived from Phil Brierleys freely available java code at www.philbrierley.com.

AI::NNFlex::Backprop leans towards teaching NN and cognitive modelling applications. Future modules are likely to include more biologically plausible nets like DeVries & Principes Gamma model.

Full documentation for AI::NNFlex::Dataset can be found in the modules own perldoc. It's documented here for convenience only.

=head1 CONSTRUCTOR 

=head2 AI::NNFlex::Backprop->new( parameter => value );

Parameters:

	
	randomweights=>MAXIMUM VALUE FOR INITIAL WEIGHT

	fixedweights=>WEIGHT TO USE FOR ALL CONNECTIONS

	debug=>[LIST OF CODES FOR MODULES TO DEBUG]

	learningrate=>the learning rate of the network

	momentum=>the momentum value (momentum learning only)

	round=>0 or 1 - 1 sets the network to round output values to
		nearest of 1, -1 or 0

	fahlmanconstant=>0.1
		


The following parameters are optional:

 randomweights

 fixedweights

 debug

 round

 momentum

 fahlmanconstant


If randomweights is not specified the network will default to a random value from 0 to 1.

If momentum is not specified the network will default to vanilla (non momentum) backprop.

The Fahlman constant modifies the slope of the error curve. 0.1 is the standard value for everything, and speeds the network up immensely. If no Fahlman constant is set, the network will default to 0.1

=head2 AI::NNFlex::Dataset

 new (	[[INPUT VALUES],[OUTPUT VALUES],
	[INPUT VALUES],[OUTPUT VALUES],..])

=head2 INPUT VALUES

These should be comma separated values. They can be applied to the network with ::run or ::learn

=head2 OUTPUT VALUES
	
These are the intended or target output values. Comma separated. These will be used by ::learn


=head1 METHODS

This is a short list of the main methods implemented in AI::NNFlex::Backprop.

=head2 AI::NNFlex::Backprop

=head2 add_layer

 Syntax:

 $network->add_layer(	nodes=>NUMBER OF NODES IN LAYER,
			persistentactivation=>RETAIN ACTIVATION BETWEEN PASSES,
			decay=>RATE OF ACTIVATION DECAY PER PASS,
			randomactivation=>MAXIMUM STARTING ACTIVATION,
			threshold=>NYI,
			activationfunction=>"ACTIVATION FUNCTION",
			errorfunction=>'ERROR TRANSFORMATION FUNCTION',
			randomweights=>MAX VALUE OF STARTING WEIGHTS);


The activation function must be defined in AI::NNFlex::Mathlib. Valid predefined activation functions are tanh & linear.

The error transformation function defines a transform that is done on the error value. It must be a valid function in AI::NNFlex::Mathlib. Using a non linear transformation function on the error value can sometimes speed up training.

The following parameters are optional:

 persistentactivation

 decay

 randomactivation

 threshold

 errorfunction

 randomweights



=head2 init

 Syntax:

 $network->init();

Initialises connections between nodes, sets initial weights and loads external components. Implements connections backwards and forwards from each node in each layer to each node in the preceeding and following layers, and initialises weights values on all connections. 

=head2 lesion

 $network->lesion ({'nodes'=>PROBABILITY,'connections'=>PROBABILITY})

 Damages the network.

B<PROBABILITY>

A value between 0 and 1, denoting the probability of a given node or connection being damaged.

Note: this method may be called on a per network, per node or per layer basis using the appropriate object.

=head2 AN::NNFlex::Dataset

=head2 learn

 $dataset->learn($network)

'Teaches' the network the dataset using the networks defined learning algorithm. Returns sqrError;

=head2 run

 $dataset->run($network)

Runs the dataset through the network and returns a reference to an array of output patterns.

=head1 EXAMPLES

See the code in ./examples. For any given version of NNFlex, xor.pl will contain the latest functionality.


=head1 PREREQs

None. NNFlex::Backprop should run OK on any version of Perl 5 >. 


=head1 ACKNOWLEDGEMENTS

Phil Brierley, for his excellent free java code, that solved my backprop problem

Dr Martin Le Voi, for help with concepts of NN in the early stages

Dr David Plaut, for help with the project that this code was originally intended for.

Graciliano M.Passos for suggestions & improved code (see SEE ALSO).

Dr Scott Fahlman, whose very readable paper 'An empirical study of learning speed in backpropagation networks' (1988) has driven many of the improvements made so far.

=head1 SEE ALSO

 AI::NNFlex

 AI::NNEasy - Developed by Graciliano M.Passos 
 Shares some common code with NNFlex. 
 

=head1 TODO



=head1 CHANGES


=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net



=cut

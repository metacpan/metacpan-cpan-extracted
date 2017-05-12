##########################################################
# AI::NNFlex::Reinforce
##########################################################
# NNFlex learning module
# this is a bit of an experimental one. All it does is
# Reinforce the weight depending on the sign & activity
# of the node, sort of a gross oversimplification of a
# neuron.
#
##########################################################
# Versions
# ========
#
# 1.0	20041125	CColbourn	New module
# 1.1	20050116	CColbourn	Fixed reverse @layers
#					bug reported by GM Passos
#
# 1.2	20050218	CColbourn	Mod'd to change weight
#					addressing from hash to
#					array for nnf0.16
#
# 1.3	20050307	CColbourn	repackaged as a subclass
#					of nnflex
#
##########################################################
# ToDo
# ----
#
#
###########################################################
#

package AI::NNFlex::Reinforce;
use AI::NNFlex;
use AI::NNFlex::Feedforward;
use base qw(AI::NNFlex AI::NNFlex::Feedforward);
use strict;


###########################################################
#AI::NNFlex::Reinforce::learn
###########################################################
sub learn
{

	my $network = shift;

	my @layers = @{$network->{'layers'}};

	# no connections westwards from input, so no weights to adjust
	shift @layers;

	# reverse to start with the last layer first
	foreach my $layer (reverse @layers)
	{
		my @nodes = @{$layer->{'nodes'}};

		foreach my $node (@nodes)
		{
			my @westNodes = @{$node->{'connectedNodesWest'}->{'nodes'}};
			my @westWeights = @{$node->{'connectedNodesWest'}->{'weights'}};
			my $connectedNodeCounter=0;
			foreach my $westNode (@westNodes)
			{
				my $dW = $westNode->{'activation'} * $westWeights[$connectedNodeCounter] * $network->{'learning rate'};
				$node->{'connectedNodesWest'}->{'weights'}->[$connectedNodeCounter] += $dW;
			}
		}
	}
}



1;

=pod

=head1 NAME

AI::NNFlex::Reinforce - A very simple experimental NN module

=head1 SYNOPSIS

 use AI::NNFlex::Reinforce;

 my $network = AI::NNFlex::Reinforce->new(config parameter=>value);

 $network->add_layer(nodes=>x,activationfunction=>'function');

 $network->init(); 



 use AI::NNFlex::Dataset;

 my $dataset = AI::NNFlex::Dataset->new([
			[INPUTARRAY],[TARGETOUTPUT],
			[INPUTARRAY],[TARGETOUTPUT]]);

 my $sqrError = 10;

 for (1..100)

 {

	 $dataset->learn($network);

 }

 $network->lesion({'nodes'=>PROBABILITY,'connections'=>PROBABILITY});

 $network->dump_state(filename=>'badgers.wts');

 $network->load_state(filename=>'badgers.wts');

 my $outputsRef = $dataset->run($network);

 my $outputsRef = $network->output(layer=>2,round=>1);

=head1 DESCRIPTION

Reinforce is a very simple NN module. It's mainly included in this distribution to provide an example of how to subclass AI::NNFlex to write your own NN modules. The training method strengthens any connections that are active during the run pass.

=head1 CONSTRUCTOR 

=head2 AI::NNFlex::Reinforce

 new ( parameter => value );
	
	randomweights=>MAXIMUM VALUE FOR INITIAL WEIGHT

	fixedweights=>WEIGHT TO USE FOR ALL CONNECTIONS

	debug=>[LIST OF CODES FOR MODULES TO DEBUG]

	learningrate=>the learning rate of the network

	round=>0 or 1 - 1 sets the network to round output values to
		nearest of 1, -1 or 0


The following parameters are optional:
 randomweights
 fixedweights
 debug
 round

(Note, if randomweights is not specified the network will default to a random value from 0 to 1.


=head1 METHODS

This is a short list of the main methods implemented in AI::NNFlex. Subclasses may implement other methods.

=head2 AI::NNFlex

=head3 add_layer

 Syntax:

 $network->add_layer(	nodes=>NUMBER OF NODES IN LAYER,
			persistentactivation=>RETAIN ACTIVATION BETWEEN PASSES,
			decay=>RATE OF ACTIVATION DECAY PER PASS,
			randomactivation=>MAXIMUM STARTING ACTIVATION,
			threshold=>NYI,
			activationfunction=>"ACTIVATION FUNCTION",
			randomweights=>MAX VALUE OF STARTING WEIGHTS);

=head3 init

 Syntax:

 $network->init();

Initialises connections between nodes, sets initial weights and loads external components. The base AI::NNFlex init method implementes connections backwards and forwards from each node in each layer to each node in the preceeding and following layers. 

=head3 lesion

 $network->lesion ({'nodes'=>PROBABILITY,'connections'=>PROBABILITY})

 Damages the network.

B<PROBABILITY>

A value between 0 and 1, denoting the probability of a given node or connection being damaged.

Note: this method may be called on a per network, per node or per layer basis using the appropriate object.

=head2 AN::NNFlex::Dataset

=head3 learn

 $dataset->learn($network)

'Teaches' the network the dataset using the networks defined learning algorithm. Returns sqrError;

=head3 run

 $dataset->run($network)

Runs the dataset through the network and returns a reference to an array of output patterns.

=head1 EXAMPLES

See the code in ./examples. For any given version of NNFlex, xor.pl will contain the latest functionality.


=head1 PREREQs

None. NNFlex::Reinforce should run OK on any version of Perl 5 >. 


=head1 ACKNOWLEDGEMENTS

Phil Brierley, for his excellent free java code, that solved my backprop problem

Dr Martin Le Voi, for help with concepts of NN in the early stages

Dr David Plaut, for help with the project that this code was originally intended for.

Graciliano M.Passos for suggestions & improved code (see SEE ALSO).

Dr Scott Fahlman, whose very readable paper 'An empirical study of learning speed in backpropagation networks' (1988) has driven many of the improvements made so far.

=head1 SEE ALSO

 AI::NNFlex
 AI::NNFlex::Backprop
 AI::NNFlex::Dataset


=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net



=cut

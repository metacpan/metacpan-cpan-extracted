####################################################
# AI::NNFlex::Hopfield
####################################################
# Hopfield network simulator
####################################################
#
# Version history
# ===============
#
# 1.0	20050330	CColbourn	New module
#
####################################################
package AI::NNFlex::Hopfield;

use strict;
use AI::NNFlex;
use AI::NNFlex::Mathlib;
use Math::Matrix;
use base qw(AI::NNFlex AI::NNFlex::Mathlib);

####################################################
# AI::NNFlex::Hopfield::init
####################################################
#
# The hopfield network has connections from every
# node to every other node, rather than being 
# arranged in distinct layers like a feedforward
# network. We can retain the layer architecture to
# give us blocks of nodes, but need to overload init
# to perform full connections
#
#####################################################
sub init
{

	my $network = shift;
	my @nodes;

	# Get a list of all the nodes in the network
	foreach my $layer (@{$network->{'layers'}})
	{
		foreach my $node (@{$layer->{'nodes'}})
		{
			# cover the assumption that some inherited code
			# will require an activation function
			if (!$node->{'activationfunction'})
			{
				$node->{'activationfunction'}= 'hopfield_threshold';
				$node->{'activation'} =0;
				$node->{'lastactivation'} = 0;
			}
			push @nodes,$node;
		}
	}

	# we'll probably need this later
	$network->{'nodes'} = \@nodes;

	foreach my $node (@nodes)
	{
		my @connectedNodes;
		foreach my $connectedNode (@nodes)
		{
			push @connectedNodes,$connectedNode;
		}
		my @weights;
		$node->{'connectednodes'}->{'nodes'} = \@connectedNodes;
		for (0..(scalar @nodes)-1)
		{
			push @weights,$network->calcweight();
		}
		$node->{'connectednodes'}->{'weights'} = \@weights
	}

	return 1;

}

##########################################################
# AI::NNFlex::Hopfield::run
##########################################################
# apply activation patterns & calculate activation
# through the network
##########################################################
sub run
{
	my $network = shift;

	my $inputPatternRef = shift;

	my @inputpattern = @$inputPatternRef;

	if (scalar @inputpattern != scalar @{$network->{'nodes'}})
	{
		return "Error: input pattern does not match number of nodes"
	}

	# apply the pattern to the network
	my $counter=0;
	foreach my $node (@{$network->{'nodes'}})
	{
		$node->{'activation'} = $inputpattern[$counter];
		$counter++;
	}

	# Now update the network with activation flow
	foreach my $node (@{$network->{'nodes'}})
	{
		$node->{'activation'}=0;
		my $counter=0;
		foreach my $connectedNode (@{$node->{'connectednodes'}->{'nodes'}})
		{
			# hopfield nodes don't have recursive connections
			unless ($node == $connectedNode)
			{
				$node->{'activation'} += $connectedNode->{'activation'} * $node->{'connectednodes'}->{'weights'}->[$counter];

			}
			$counter++;
		}


		# bias
		$node->{'activation'} += 1 * $node->{'connectednodes'}->{'weights'}->[-1];

		my $activationfunction = $node->{'activationfunction'};
		$node->{'activation'} = $network->$activationfunction($node->{'activation'});

	}

	return $network->output;
}

#######################################################
# AI::NNFlex::Hopfield::output
#######################################################
# This needs to be overloaded, because the default
# nnflex output method returns only the rightmost layer
#######################################################
sub output
{
	my $network = shift;

	my @array;
	foreach my $node (@{$network->{'nodes'}})
	{
		unshift @array,$node->{'activation'};
	}

	return \@array;
}

########################################################
# AI::NNFlex::Hopfield::learn
########################################################
sub learn
{
	my $network = shift;

	my $dataset = shift;

	# calculate the weights
	# turn the dataset into a matrix
	my @matrix;
	foreach (@{$dataset->{'data'}})
	{
		push @matrix,$_;
	}
	my $patternmatrix = Math::Matrix->new(@matrix);

	my $inversepattern = $patternmatrix->transpose;

	my @minusmatrix;

	for (my $rows=0;$rows <(scalar @{$network->{'nodes'}});$rows++)
	{
		my @temparray;
		for (my $cols=0;$cols <(scalar	@{$network->{'nodes'}});$cols++)
		{
			if ($rows == $cols)
			{
				my $numpats = scalar @{$dataset->{'data'}};
				push @temparray,$numpats;	
			}
			else
			{
				push @temparray,0;
			}
		}
		push @minusmatrix,\@temparray;
	}

	my $minus = Math::Matrix->new(@minusmatrix);

	my $product = $inversepattern->multiply($patternmatrix);

	my $weights = $product->subtract($minus);

	my @element = ('1');
	my @truearray;
	for (1..scalar @{$dataset->{'data'}}){push @truearray,"1"}
	
	my $truematrix = Math::Matrix->new(\@truearray);

	my $thresholds = $truematrix->multiply($patternmatrix);
	#$thresholds = $thresholds->transpose();

	my $counter=0;
	foreach (@{$network->{'nodes'}})
	{
		my @slice;
		foreach (@{$weights->slice($counter)})
		{
			push @slice,$$_[0];
		}

		push @slice,${$thresholds->slice($counter)}[0][0];

		$_->{'connectednodes'}->{'weights'} = \@slice;
		$counter++;
	}

	return 1;

}



1;

=pod

=head1 NAME

AI::NNFlex::Hopfield - a fast, pure perl Hopfield network simulator

=head1 SYNOPSIS

 use AI::NNFlex::Hopfield;

 my $network = AI::NNFlex::Hopfield->new(config parameter=>value);

 $network->add_layer(nodes=>x);

 $network->init(); 



 use AI::NNFlex::Dataset;

 my $dataset = AI::NNFlex::Dataset->new([
			[INPUTARRAY],
			[INPUTARRAY]]);

 $network->learn($dataset);

 my $outputsRef = $dataset->run($network);

 my $outputsRef = $network->output();

=head1 DESCRIPTION

AI::NNFlex::Hopfield is a Hopfield network simulator derived from the AI::NNFlex class. THIS IS THE FIRST ALPHA CUT OF THIS MODULE! Any problems, let me know and I'll fix them.

Hopfield networks differ from feedforward networks in that they are effectively a single layer, with all nodes connected to all other nodes (except themselves), and are trained in a single operation. They are particularly useful for recognising corrupt bitmaps etc. I've left the multi layer architecture in this module (inherited from AI::NNFlex) for convenience of visualising 2d bitmaps, but effectively its a single layer.

Full documentation for AI::NNFlex::Dataset can be found in the modules own perldoc. It's documented here for convenience only.

=head1 CONSTRUCTOR 

=head2 AI::NNFlex::Hopfield->new();

=head2 AI::NNFlex::Dataset

 new (	[[INPUT VALUES],[INPUT VALUES],
	[INPUT VALUES],[INPUT VALUES],..])

=head2 INPUT VALUES

These should be comma separated values. They can be applied to the network with ::run or ::learn

=head2 OUTPUT VALUES
	
These are the intended or target output values. Comma separated. These will be used by ::learn


=head1 METHODS

This is a short list of the main methods implemented in AI::NNFlex::Hopfield.

=head2 AI::NNFlex::Hopfield

=head2 add_layer

 Syntax:

 $network->add_layer(	nodes=>NUMBER OF NODES IN LAYER	);

=head2 init

 Syntax:

 $network->init();

Initialises connections between nodes.

=head2 run

 $network->run($dataset)

Runs the dataset through the network and returns a reference to an array of output patterns.

=head1 EXAMPLES

See the code in ./examples.


=head1 PREREQs

Math::Matrix

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

 AI::NNFlex
 AI::NNFlex::Backprop


=head1 TODO

More detailed documentation. Better tests. More examples.

=head1 CHANGES

v0.1 - new module

=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net



=cut

##########################################################
# AI::NNFlex::Feedforward
##########################################################
# This is the first propagation module for NNFlex
#
##########################################################
# Versions
# ========
#
# 1.0	20040910	CColbourn	New module
#
# 1.1	20050116	CColbourn	Added call to 
#					datasets where run
#					is erroneously called
#					with a dataset
#
# 1.2	20050206	CColbourn	Fixed a bug where
#					transfer function
#					was called on every
#					input to a node
#					instead of total
#
# 1.3	20050218	CColbourn	Changed to reflect
#					new weight indexing
#					(arrays) in nnflex 0.16
#
# 1.4	20050302	CColbourn	Fixed a problem that allowed
#					activation to flow even if a
#					node was lesioned off
#
# 1.5	20050308	CColbourn	Made a separate class as part
#					of NNFlex-0.2
#
# 1.6	20050313	CColbourn	altered syntax of activation
#					function call to get rid of
#					eval
#
##########################################################
# ToDo
# ----
#
#
###########################################################
#
package AI::NNFlex::Feedforward;

use strict;


###########################################################
# AI::NNFlex::Feedforward::run
###########################################################
#
#This class contains the run method only. The run method performs
#Feedforward  (i.e. west to east) activation flow on the network.
#
#This class is internal to the NNFlex package, and is included
#in the NNFlex namespace by a require on the networktype parameter.
#
#syntax:
# $network->run([0,1,1,1,0,1,1]);
#
#
###########################################################
sub run
{
	my $network = shift;

	my $inputPatternRef = shift;
	
	# if this is an incorrect dataset call translate it
	if ($inputPatternRef =~/Dataset/)
	{
		return ($inputPatternRef->run($network))
	}


	my @inputPattern = @$inputPatternRef;

	my @debug = @{$network->{'debug'}};
	if (scalar @debug> 0)
	{$network->dbug ("Input pattern @inputPattern received by Feedforward",3);}


	# First of all apply the activation pattern to the input units (checking
	# that the pattern has the right number of values)

	my $inputLayer = $network->{'layers'}->[0]->{'nodes'};

	if (scalar @$inputLayer != scalar @inputPattern)
	{	
		$network->dbug("Wrong number of input values",0);
		return 0;
	}

	# Now apply the activation
	my $counter=0;
	foreach (@$inputLayer)
	{	
		if ($_->{'active'})
		{

			if ($_->{'persistentactivation'})
			{
				$_->{'activation'} +=$inputPattern[$counter];
				if (scalar @debug> 0)
				{$network->dbug("Applying ".$inputPattern[$counter]." to $_",3);}
			}
			else
			{
				$_->{'activation'} =$inputPattern[$counter];
				if (scalar @debug> 0)
				{$network->dbug("Applying ".$inputPattern[$counter]." to $_",3);}
			 
			}
		}
		$counter++;
	}
	

	# Now flow activation through the network starting with the second layer
	foreach my $layer (@{$network->{'layers'}})
	{
		if ($layer eq $network->{'layers'}->[0]){next}

		foreach my $node (@{$layer->{'nodes'}})
		{
			my $totalActivation;
			# Set the node to 0 if not persistent
			if (!($node->{'persistentactivation'}))
			{
				$node->{'activation'} =0;
			}

			# Decay the node (note that if decay is not set this
			# will have no effect, hence no if).
			$node->{'activation'} -= $node->{'decay'};
			my $nodeCounter=0;
			foreach my $connectedNode (@{$node->{'connectedNodesWest'}->{'nodes'}})
			{
				if (scalar @debug> 0)
				{$network->dbug("Flowing from ".$connectedNode->{'nodeid'}." to ".$node->{'nodeid'},3);}
	
				my $weight = ${$node->{'connectedNodesWest'}->{'weights'}}[$nodeCounter];
				my $activation = $connectedNode->{'activation'};		
				if (scalar @debug> 0)
				{$network->dbug("Weight & activation: $weight - $activation",3);}
				

				$totalActivation += $weight*$activation;
				$nodeCounter++;	
			}

			if ($node->{'active'})
			{
				my $value = $totalActivation;

				my $function = $node->{'activationfunction'};
				#my $functionCall ="\$value = \$network->$function(\$value);";

				#eval($functionCall);
				$value = $network->$function($value);
				$node->{'activation'} = $value;
			}
			if (scalar @debug> 0)
			{$network->dbug("Final activation of ".$node->{'nodeid'}." = ".$node->{'activation'},3);}
		}
	}



	return $network->output;

}





1;

=pod

=head1 NAME

AI::NNFlex::Feedforward - methods for feedforward neural networks

=head1 SYNOPSIS

 use AI::NNFlex::Feedforward;

 $network->run([array of inputs]);

=head1 DESCRIPTION

AI::NNFlex::Feedforward provides a run method to flow activation through an NNFlex network in west to east feedforward style. 

=head1 CONSTRUCTOR 

None

=head1 METHODS

=head1 AI::NNFlex::Feedforward::run

takes an array of inputs for the network. Returns true or false.

=head1 SEE ALSO

 
 AI::NNFlex
 AI::NNFlex::Backprop
 AI::NNFlex::Dataset 


=head1 CHANGES



=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net

=cut

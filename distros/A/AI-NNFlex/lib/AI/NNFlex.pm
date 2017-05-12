use strict;
use vars qw ($VERSION);
#use warnings;
###############################################################################
# NNFlex - Neural Network (flexible) - a heavily custom NN simulator
# 
# Sept 2004 - CW Colbourn
#
# This was developed from the abortive nnseq package originally intended
# for real time neural networks.
# The basis of the approach for this version is a very flexible, modular
# set of packages. This package constitutes the base, allowing the modeller
# to create meshes, apply input, and read output ONLY!
#
# Separate modules are to be written to perform feedback adjustments,
# various activation functions, text/gui front ends etc
#
###############################################################################
# Version Control
# ===============
#
# 0.1 20040905		CColbourn	New module
#					added NNFlex::datasets
#
# 0.11 20050113		CColbourn	Added NNFlex::lesion
#					Improved Draw
#					added NNFlex::datasets
#
# 0.12 20050116		CColbourn	Fixed reinforce.pm bug
# 					Added call into datasets
#					in ::run to offer alternative
#					syntax
#
# 0.13 20050121		CColbourn	Created momentum learning module
#
# 0.14 20050201		CColbourn	Abstracted derivatiive of activation
#					function into a separate function call
#					instead of hardcoded 1-y*y in backprop
#					tanh, linear & momentum
#
# 0.15 20050206		CColbourn	Fixed a bug in feedforward.pm. Stopped
#					calling dbug unless scalar debug > 0
#					in a lot of calls
#
# 0.16 20050218		CColbourn	Changed from a hash of weights to an
# 					array of weights, to make it easier
# 					to adapt the code to PDL
#
# 0.17 20050302		CColbourn	Changed input params to ::output to
#					be param=>parameter not anon hash
#					Included round parameter in output
#
# 0.20 20050307		CColbourn	Modified for inheritance to simplify
#					future network types
#
# 0.21 20050316		CColbourn	Rewrote perldocs, implemented fahlman
#					constant, chopped out old legacy stuff
#					put math functions in mathlib, etc etc
#
# 0.22 20050317		CColbourn	Implemented ::connect method
#
# 0.23 20050424		CColbourn	Included Hopfield module in dist.
#
# 0.24 20050620		CColbourn	Corrected a bug in the bias weight
#					calculation
#
#
###############################################################################
# ToDo
# ====
#
# Modify init to allow recurrent layer/node connections
# write cmd & gui frontends
# Speed the bugger up!
#
# Odd thought - careful coding of a network would allow grafting of
# two different network types or learning algorithms, like an effectve
# single network with 2 layers unsupervised and 2 layers supervised
#
# Clean up the perldocs
#
###############################################################################
$VERSION = "0.24";


###############################################################################
my @DEBUG; 	# a single, solitary, shameful global variable. Couldn't
		#avoid it really. It allows correct control of debug
		#information before the $network object is created
		# (in ::layer->new & ::node->new for  example).


###############################################################################
###############################################################################
# package NNFlex
###############################################################################
###############################################################################
package AI::NNFlex;
use AI::NNFlex::Mathlib;
use base qw(AI::NNFlex::Mathlib);





###############################################################################
# AI::NNFlex::new
###############################################################################
sub new
{
	my $class = shift;
	my $network={};
	bless $network,$class;

	# intercept the new style 'empty network' constructor call
	# Maybe I should deprecate the old one, but its convenient, provided you
	# can follow the mess of hashes
	
	if (!grep /HASH/,@_)
	{
		my %config = @_;
		foreach (keys %config)
		{
			$network->{$_} = $config{$_};
		}

		return $network;
	}

	# Otherwise, continue assuming that the whole network is defined in 
	# a pair of anonymous hashes	



	my $params = shift;
	my $netParams = shift;
	my @layers;
	dbug ($netParams,"Entered AI::NNFlex::new with params $params $netParams",2);


	# clean up case & spaces in layer defs from pre 0.14 constructor calls:
	my $cleanParams;
	foreach my $layer(@{$params})
	{
		my %cleanLayer;
		foreach (keys %$layer)
		{
			my $key = lc($_);
			$key =~ s/\s//g;
			$cleanLayer{$key} = $$layer{$_};
		}
		push @$cleanParams,\%cleanLayer;
	}



	# Network wide parameters (e.g. random weights)
	foreach (keys %$netParams)
	{
		my $key = lc($_);
		$key =~ s/\s//g; # up to 0.14 we had params with spaces in, now deprecated
		$network->{$key} = ${$netParams}{$_};
	}

	if( $network->{'debug'})
	{
		@DEBUG = @{$network->{'debug'}};
	}

	# build the network
	foreach (@$cleanParams)
	{
		if (!($$_{'nodes'})){next}
		my %layer = %{$_};	
		push @layers,AI::NNFlex::layer->new(\%layer);	
	}	
	$$network{'layers'} = \@layers;





	$network->init;
	return $network;
}




###############################################################################
# AI::NNFlex::add_layer
###############################################################################
#
# Adds a layer of given node definitions to the $network object
#
# syntax
#
# $network->add_layer(nodes=>4,activationfunction=>tanh);
#
# returns bool success or failure
#
###############################################################################

sub add_layer
{
	my $network = shift;

	my %config = @_;

	my $layer = AI::NNFlex::layer->new(\%config);

	if ($layer)
	{
		push @{$network->{'layers'}},$layer;
		return 1;
	}
	else
	{
		return 0;
	}
}


###############################################################################
# AI::NNFlex::output
###############################################################################
sub output
{
	my $network = shift;
	my %params = @_;

	my $finalLayer = ${$$network{'layers'}}[-1];

	my $outputLayer;

	if (defined $params{'layer'})
	{
		$outputLayer = ${$$network{'layers'}}[$params{'layer'}]
	}
	else
	{
		$outputLayer = $finalLayer
	}

	my $output = AI::NNFlex::layer::layer_output($outputLayer);


	# Round outputs if required
	if ($network->{'round'})
	{
		foreach (@$output)
		{
			if ($_ > 0.5)
			{
				$_ = 1;
			}
			elsif ($_ < -0.5)
			{
				$_=-1;
			}
			else
			{
				$_=0;
			}
		}
	}

	return $output;
}

################################################################################
# sub init
################################################################################
sub init
{

	#Revised version of init for NNFlex

	my $network = shift;
	my @layers = @{$network->{'layers'}};

	# if network debug state not set, set it to null
	if (!$network->{'debug'})
	{
		$network->{'debug'} = [];
	}
	my @debug = @{$network->{'debug'}};
	

	# implement the bias node
	if ($network->{'bias'})
	{
		my $biasNode = AI::NNFlex::node->new({'activation function'=>'linear'});
		$$network{'biasnode'} = $biasNode;
		$$network{'biasnode'}->{'activation'} = 1;
		$$network{'biasnode'}->{'nodeid'} = "bias";
	}

	my $nodeid = 1;
	my $currentLayer=0;	
	# foreach layer, we need to examine each node
	foreach my $layer (@layers)
	{
		# Foreach node we need to make connections east and west
		foreach my $node (@{$layer->{'nodes'}})
		{
			$node->{'nodeid'} = $nodeid;
			# only initialise to the west if layer > 0
			if ($currentLayer > 0 )
			{
				foreach my $westNodes (@{$network->{'layers'}->[$currentLayer -1]->{'nodes'}})	
				{
					foreach my $connectionFromWest (@{$westNodes->{'connectedNodesEast'}->{'nodes'}})
					{
						if ($connectionFromWest eq $node)
						{
							my $weight = $network->calcweight;
				
							push @{$node->{'connectedNodesWest'}->{'nodes'}},$westNodes;
							push @{$node->{'connectedNodesWest'}->{'weights'}},$weight;
							if (scalar @debug > 0)	
							{$network->dbug ("West to east Connection - ".$westNodes->{'nodeid'}." to ".$node->{'nodeid'},2);}
						}
					}
				}
			}

			# Now initialise connections to the east (if not last layer)
			if ($currentLayer < (scalar @layers)-1)
			{
			foreach my $eastNodes (@{$network->{'layers'}->[$currentLayer+1]->{'nodes'}})
			{
				if (!$network->{'randomconnections'}  || $network->{'randomconnections'} > rand(1))
				{
					my $weight = $network->calcweight;
					push @{$node->{'connectedNodesEast'}->{'nodes'}},$eastNodes;
					push @{$node->{'connectedNodesEast'}->{'weights'}}, $weight;
					if (scalar @debug > 0)
					{$network->dbug ("East to west Connection ".$node->{'nodeid'}." to ".$eastNodes->{'nodeid'},2);}
				}
			}
			}
			$nodeid++;
		}
		$currentLayer++;
	}


	# add bias node to westerly connections
	if ($network->{'bias'})
	{
		foreach my $layer (@{$network->{'layers'}})
		{
			foreach my $node (@{$layer->{'nodes'}})
			{
				push @{$node->{'connectedNodesWest'}->{'nodes'}},$network->{'biasnode'};
				my $weight = $network->calcweight;

				push @{$node->{'connectedNodesWest'}->{'weights'}},$weight;
				if (scalar @debug > 0)
				{$network->dbug ("West to east Connection - bias to ".$node->{'nodeid'}." weight = $weight",2);}
			}
		}
	}



	return 1; # return success if we get to here


}

###############################################################################
# sub $network->dbug
###############################################################################
sub dbug
{
	my $network = shift;
	my $message = shift;
	my $level = shift;


	my @DEBUGLEVELS;
	# cover for debug calls before the network is created
	if (!$network->{'debug'})
	{
		@DEBUGLEVELS=@DEBUG;
	}
	else
	{
		@DEBUGLEVELS = @{$network->{'debug'}};
	}


	# 0 is error so ALWAYS display
	if (!(grep /0/,@DEBUGLEVELS)){push @DEBUGLEVELS,0}

	foreach (@DEBUGLEVELS)
	{
	
		if ($level == $_)
		{
			print "$message\n";
		}
	}
}


###############################################################################
# AI::NNFlex::dump_state
###############################################################################
sub dump_state
{
	my $network = shift;
	my %params =@_;

	my $filename = $params{'filename'};
	my $activations = $params{'activations'};

	
	open (OFILE,">$filename") or return "Can't create weights file $filename";


	foreach my $layer (@{$network->{'layers'}})
	{
		foreach my $node (@{$layer->{'nodes'}})
		{
			if ($activations)
			{
				print OFILE $node->{'nodeid'}." activation = ".$node->{'activation'}."\n";
			}
			my $connectedNodeCounter=0;
			foreach my $connectedNode (@{$node->{'connectedNodesEast'}->{'nodes'}})
			{
				my $weight = ${$node->{'connectedNodesEast'}->{'weights'}}[$connectedNodeCounter];
				print OFILE $node->{'nodeid'}." <- ".$connectedNode->{'nodeid'}." = ".$weight."\n";
				$connectedNodeCounter++;
			}

			if ($node->{'connectedNodesWest'})
			{
				my $connectedNodeCounter=0;
				foreach my $connectedNode (@{$node->{'connectedNodesWest'}->{'nodes'}})
				{
					#FIXME - a more easily read format would be connectedNode first in the file
					my $weight = ${$node->{'connectedNodesWest'}->{'weights'}}[$connectedNodeCounter];
					print OFILE $node->{'nodeid'}." -> ".$connectedNode->{'nodeid'}." = ".$weight."\n";
				}
			}
		}
	}




	close OFILE;
}

###############################################################################
# sub load_state
###############################################################################
sub load_state
{
	my $network = shift;

	my %config = @_;

	my $filename = $config{'filename'};

	open (IFILE,$filename) or return "Error: unable to open $filename because $!";

	# we have to build a map of nodeids to objects
	my %nodeMap;
	foreach my $layer (@{$network->{'layers'}})
	{
		foreach my $node (@{$layer->{'nodes'}})
		{
			$nodeMap{$node->{'nodeid'}} = $node;
		}
	}

	# Add the bias node into the map
	if ($network->{'bias'})
	{
		$nodeMap{'bias'} = $network->{'biasnode'};
	}


	my %stateFromFile;

	while (<IFILE>)
	{
		chomp $_;
		my ($activation,$nodeid,$destNode,$weight);

		if ($_ =~ /(.*) activation = (.*)/)
		{
			$nodeid = $1;
			$activation = $2;
			$stateFromFile{$nodeid}->{'activation'} = $activation;
			$network->dbug("Loading $nodeid = $activation",2);
		}
		elsif ($_ =~ /(.*) -> (.*) = (.*)/)
		{
			$nodeid = $1;
			$destNode = $2;
			$weight = $3;
			$network->dbug("Loading $nodeid -> $destNode = $weight",2);
			push @{$stateFromFile{$nodeid}->{'connectedNodesWest'}->{'weights'}},$weight;
			push @{$stateFromFile{$nodeid}->{'connectedNodesWest'}->{'nodes'}},$nodeMap{$destNode};
		}	
		elsif ($_ =~ /(.*) <- (.*) = (.*)/)
		{
			$nodeid = $1;
			$destNode = $2;
			$weight = $3;
			push @{$stateFromFile{$nodeid}->{'connectedNodesEast'}->{'weights'}},$weight;
			push @{$stateFromFile{$nodeid}->{'connectedNodesEast'}->{'nodes'}},$nodeMap{$destNode};
			$network->dbug("Loading $nodeid <- $destNode = $weight",2);
		}	
	}

	close IFILE;




	my $nodeCounter=1;

	foreach my $layer (@{$network->{'layers'}})
	{
		foreach my $node (@{$layer->{'nodes'}})
		{
			$node->{'activation'} = $stateFromFile{$nodeCounter}->{'activation'};
			$node->{'connectedNodesEast'} = $stateFromFile{$nodeCounter}->{'connectedNodesEast'};
			$node->{'connectedNodesWest'} = $stateFromFile{$nodeCounter}->{'connectedNodesWest'};
			$nodeCounter++;
		}
	}
	return 1;
}

##############################################################################
# sub lesion
##############################################################################
sub lesion
{
	
        my $network = shift;

        my %params =  @_;
	my $return;
        $network->dbug("Entered AI::NNFlex::lesion with %params",2);

        my $nodeLesion = $params{'nodes'};
        my $connectionLesion = $params{'connections'};

        # go through the layers & node inactivating random nodes according
        # to probability
        
	foreach my $layer (@{$network->{'layers'}})
	{
		$return = $layer->lesion(%params);
	}

	return $return;

}

########################################################################
# AI::NNFlex::connect
########################################################################
#
# Joins layers or  nodes together.
#
# takes fromlayer=>INDEX, tolayer=>INDEX or
# fromnode=>[LAYER,NODE],tonode=>[LAYER,NODE]
#
# returns success or failure
#
#
#########################################################################
sub connect
{
	my $network = shift;
	my %params = @_;
	my $result = 0;

	if ($params{'fromnode'})
	{
		$result = $network->connectnodes(%params);
	}
	elsif ($params{'fromlayer'})
	{
		$result = $network->connectlayers(%params);
	}
	return $result;

}

########################################################################
# AI::NNFlex::connectlayers
########################################################################
sub connectlayers
{
	my $network=shift;
	my %params = @_;

	my $fromlayerindex = $params{'fromlayer'};
	my $tolayerindex = $params{'tolayer'};

	foreach my $node (@{$network->{'layers'}->[$tolayerindex]->{'nodes'}})
	{
		foreach my $connectedNode ( @{$network->{'layers'}->[$fromlayerindex]->{'nodes'}})
		{
			my $weight1 = $network->calcweight;
			my $weight2 = $network->calcweight;
			push @{$node->{'connectedNodesWest'}->{'nodes'}},$connectedNode;
			push @{$connectedNode->{'connectedNodesEast'}->{'nodes'}},$node;
			push @{$node->{'connectedNodesWest'}->{'weights'}},$weight1;
			push @{$connectedNode->{'connectedNodesEast'}->{'weights'}},$weight2;
		}
	}

	return 1;
}

##############################################################
# sub AI::NNFlex::connectnodes
##############################################################
sub connectnodes
{
	my $network = shift;
	my %params = @_;

	$params{'tonode'} =~ s/\'//g;
	$params{'fromnode'} =~ s/\'//g;
	my @tonodeindex = split /,/,$params{'tonode'};
	my @fromnodeindex = split /,/,$params{'fromnode'};

	#make the connections
	my $node = $network->{'layers'}->[$tonodeindex[0]]->{'nodes'}->[$tonodeindex[1]];
	my $connectedNode = $network->{'layers'}->[$fromnodeindex[0]]->{'nodes'}->[$fromnodeindex[1]];

	my $weight1 = $network->calcweight;
	my $weight2 = $network->calcweight;

	push @{$node->{'connectedNodesWest'}->{'nodes'}},$connectedNode;
	push @{$connectedNode->{'connectedNodesEast'}->{'nodes'}},$node;
	push @{$node->{'connectedNodesWest'}->{'weights'}},$weight1;
	push @{$connectedNode->{'connectedNodesEast'}->{'weights'}},$weight2;


	return 1;
}



##############################################################
# AI::NNFlex::calcweight
##############################################################
#
# calculate an initial weight appropriate for the network
# settings.
# takes no parameters, returns weight
##############################################################
sub calcweight
{
	my $network= shift;
	my $weight;
	if ($network->{'fixedweights'})
	{
		$weight = $network->{'fixedweights'};
	}
	elsif ($network->{'randomweights'})
	{
		$weight = (rand(2*$network->{'randomweights'}))-$network->{'randomweights'};
	}
	else
	{
		$weight = (rand(2))-1;
	}
				

	return $weight;
}





###############################################################################
###############################################################################
# Package AI::NNFlex::layer
###############################################################################
###############################################################################
package AI::NNFlex::layer;


###############################################################################
# AI::NNFlex::layer::new
###############################################################################
sub new
{
	my $class = shift;
	my $params = shift;
	my $layer ={};	

	foreach (keys %{$params})
	{
		$$layer{$_} = $$params{$_}
	}	
	bless $layer,$class;
	 
	my $numNodes = $$params{'nodes'};
	
	my @nodes;

	for (1..$numNodes)
	{
		push @nodes, AI::NNFlex::node->new($params);
	}

	$$layer{'nodes'} = \@nodes;

	AI::NNFlex::dbug($params,"Created layer $layer",2);
	return $layer;
}

###############################################################################
# AI::NNFlex::layer::layer_output
##############################################################################
sub layer_output
{
	my $layer = shift;
	my $params = shift;


	my @outputs;
	foreach my $node (@{$$layer{'nodes'}})
	{
		push @outputs,$$node{'activation'};
	}

	return \@outputs;	
}



##############################################################################
# sub lesion
##############################################################################
sub lesion
{
        
        my $layer = shift;

        my %params =  @_;
        my $return;


        my $nodeLesion = $params{'nodes'};
        my $connectionLesion = $params{'connections'};

        # go through the layers & node inactivating random nodes according
        # to probability
        
        foreach my $node (@{$layer->{'nodes'}})
        {
                $return = $node->lesion(%params);
        }

        return $return;

}



###############################################################################
###############################################################################
# package AI::NNFlex::node
###############################################################################
###############################################################################
package AI::NNFlex::node;


###############################################################################
# AI::NNFlex::node::new
###############################################################################
sub new
{
	my $class = shift;
	my $params = shift;
	my $node = {};

	foreach (keys %{$params})
	{
		$$node{$_} = $$params{$_}
	}	

	if ($$params{'randomactivation'})
	{
		$$node{'activation'} = 
			rand($$params{'random'});
			AI::NNFlex::dbug($params,"Randomly activated at ".$$node{'activation'},2);
	}
	else
	{
		$$node{'activation'} = 0;
	}
	$$node{'active'} = 1;
	
	$$node{'error'} = 0;
	
	bless $node,$class;	
	AI::NNFlex::dbug($params,"Created node $node",2);
	return $node;
}

##############################################################################
# sub lesion
##############################################################################
sub lesion
{

        my $node = shift;

        my %params =  @_;


        my $nodeLesion = $params{'nodes'};
        my $connectionLesion = $params{'connections'};

        # go through the layers & node inactivating random nodes according
        # to probability
        
	if ($nodeLesion)
	{
		my $probability = rand(1);
		if ($probability < $nodeLesion)
		{
			$node->{'active'} = 0;
		}
	}

	if ($connectionLesion)
	{
		# init works from west to east, so we should here too
		my $nodeCounter=0;
		foreach my $connectedNode (@{$node->{'connectedNodesEast'}->{'nodes'}})
		{
			my $probability = rand(1);
			if ($probability < $connectionLesion)
			{
				my $reverseNodeCounter=0; # maybe should have done this differntly in init, but 2 late now!
				${$node->{'connectedNodesEast'}->{'nodes'}}[$nodeCounter] = undef;
				foreach my $reverseConnection (@{$connectedNode->{'connectedNodesWest'}->{'nodes'}})
				{
					if ($reverseConnection == $node)
					{
						${$connectedNode->{'connectedNodesEast'}->{'nodes'}}[$reverseNodeCounter] = undef;
					}
					$reverseNodeCounter++;
				}

			}
                                
			$nodeCounter++;
		}


        }
        

        return 1;
}

1;

=pod

=head1 NAME

AI::NNFlex - A base class for implementing neural networks

=head1 SYNOPSIS

 use AI::NNFlex;

 my $network = AI::NNFlex->new(config parameter=>value);

 $network->add_layer(	nodes=>x,
 			activationfunction=>'function');

 $network->init(); 

 $network->lesion(	nodes=>PROBABILITY,
			connections=>PROBABILITY);

 $network->dump_state (filename=>'badgers.wts');

 $network->load_state (filename=>'badgers.wts');

 my $outputsRef = $network->output(layer=>2,round=>1);


=head1 DESCRIPTION

AI::NNFlex is a base class for constructing your own neural network modules. To implement a neural network, start with the documentation for AI::NNFlex::Backprop, included in this distribution

=head1 CONSTRUCTOR 

=head2 AI::NNFlex->new ( parameter => value );
	

randomweights=>MAXIMUM VALUE FOR INITIAL WEIGHT

fixedweights=>WEIGHT TO USE FOR ALL CONNECTIONS

debug=>[LIST OF CODES FOR MODULES TO DEBUG]

round=>0 or 1, a true value sets the network to round output values to nearest of 1, -1 or 0


The constructor implements a fairly generalised network object with a number of parameters.


The following parameters are optional:
 randomweights
 fixedweights
 debug
 round


(Note, if randomweights is not specified the network will default to a random value from 0 to 1.

=head1 METHODS

This is a short list of the main methods implemented in AI::NNFlex. 

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

Add layer adds whatever parameters you specify as attributes of the layer, so if you want to implement additional parameters simply use them in your calling code.

Add layer returns success or failure, and if successful adds a layer object to the $network->{'layers'} array. This layer object contains an attribute $layer->{'nodes'}, which is an array of nodes in the layer.

=head3 init

 Syntax:

 $network->init();

Initialises connections between nodes, sets initial weights. The base AI::NNFlex init method implementes connections backwards and forwards from each node in each layer to each node in the preceeding and following layers. 

init adds the following attributes to each node:

=over

=item *
{'connectedNodesWest'}->{'nodes'} - an array of node objects connected to this node on the west/left

=item *
{'connectedNodesWest'}->{'weights'} - an array of scalar numeric weights for the connections to these nodes


=item *
{'connectedNodesEast'}->{'nodes'} - an array of node objects connected to this node on the east/right

=item *
{'connectedNodesEast'}->{'weights'} - an array of scalar numeric weights for the connections to these nodes

=back

The connections to easterly nodes are not used in feedforward networks.
Init also implements the Bias node if specified in the network config.

=head3 connect

Syntax:
 $network->connect(fromlayer=>1,tolayer=>0);
 $network->connect(fromnode=>'1,1',tonode=>'0,0');

Connect allows you to manually create connections between layers or nodes, including recurrent connections back to the same layer/node. Node indices must be LAYER,NODE, numbered from 0.

Weight assignments for the connection are calculated based on the network wide weight policy (see INIT).

=head3 lesion

 $network->lesion (nodes=>PROBABILITY,connections=>PROBABILITY)

 Damages the network.

B<PROBABILITY>

A value between 0 and 1, denoting the probability of a given node or connection being damaged.

Note: this method may be called on a per network, per node or per layer basis using the appropriate object.

=head1 EXAMPLES

See the code in ./examples. For any given version of NNFlex, xor.pl will contain the latest functionality.


=head1 PREREQs

None. NNFlex should run OK on any version of Perl 5 >. 


=head1 ACKNOWLEDGEMENTS

Phil Brierley, for his excellent free java code, that solved my backprop problem

Dr Martin Le Voi, for help with concepts of NN in the early stages

Dr David Plaut, for help with the project that this code was originally intended for.

Graciliano M.Passos for suggestions & improved code (see SEE ALSO).

Dr Scott Fahlman, whose very readable paper 'An empirical study of learning speed in backpropagation networks' (1988) has driven many of the improvements made so far.

=head1 SEE ALSO

 AI::NNFlex::Backprop
 AI::NNFlex::Feedforward
 AI::NNFlex::Mathlib
 AI::NNFlex::Dataset

 AI::NNEasy - Developed by Graciliano M.Passos 
 (Shares some common code with NNFlex)
 

=head1 TODO

 Lots of things:

 clean up the perldocs some more
 write gamma modules
 write BPTT modules
 write a perceptron learning module
 speed it up
 write a tk gui

=head1 CHANGES

v0.11 introduces the lesion method, png support in the draw module and datasets.

v0.12 fixes a bug in reinforce.pm & adds a reflector in feedforward->run to make $network->run($dataset) work.

v0.13 introduces the momentum learning algorithm and fixes a bug that allowed training to proceed even if the node activation function module can't be loaded

v0.14 fixes momentum and backprop so they are no longer nailed to tanh hidden units only.

v0.15 fixes a bug in feedforward, and reduces the debug overhead

v0.16 changes some underlying addressing of weights, to simplify and speed  

v0.17 is a bugfix release, plus some cleaning of UI

v0.20 changes AI::NNFlex to be a base class, and ships three different network types (i.e. training algorithms). Backprop & momentum are both networks of the feedforward class, and inherit their 'run' method from feedforward.pm. 0.20 also fixes a whole raft of bugs and 'not nices'.

v0.21 cleans up the perldocs more, and makes nnflex more distinctly a base module. There are quite a number of changes in Backprop in the v0.21 distribution.

v0.22 introduces the ::connect method, to allow creation of recurrent connections, and manual control over connections between nodes/layers.

v0.23 includes a Hopfield module in the distribution.

v0.24 fixes a bug in the bias weight calculations

=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net

=cut

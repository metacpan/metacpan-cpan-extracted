AI::NNFlex

This distribution now contains a reasonably well developed and fast backprop implementation, a very primitive neuron reinforcement module, the first version of my Hopfield module and a variety of utility modules to support this lot.

I expect this to carry on developing as I get closer to writing my PhD proposal - next is probably better Hopfield support, and maybe BPTT.

If you don't care about the theory and just want to use 'a neural net', you'll probably want AI::NNFlex::Backprop.

If you do care about the theory (and don't want to shell out for both volumes of 'Parallel Distributed Processing'), you could do worse than Phil Pictons 'Neural Networks' (Palgrave Grassroots series).


Charles Colbourn April 2005

###################################################################
Example XOR neural net (from examples/xor.pl


# Example demonstrating XOR with momentum backprop learning

use strict;
use AI::NNFlex::Backprop;
use AI::NNFlex::Dataset;

# Create the network 

my $network = AI::NNFlex::Backprop->new(
				learningrate=>.2,
				bias=>1,
				fahlmanconstant=>0.1,
				momentum=>0.6,
				round=>1);



$network->add_layer(	nodes=>2,
			activationfunction=>"tanh");


$network->add_layer(	nodes=>2,
			activationfunction=>"tanh");

$network->add_layer(	nodes=>1,
			activationfunction=>"linear");


$network->init();

my $dataset = AI::NNFlex::Dataset->new([
			[0,0],[0],
			[0,1],[1],
			[1,0],[1],
			[1,1],[0]]);



my $counter=0;
my $err = 10;
while ($err >.001)
{
	$err = $dataset->learn($network);
	print "Epoch = $counter error = $err\n";
	$counter++;
}


foreach (@{$dataset->run($network)})
{
	foreach (@$_){print $_}
	print "\n";	
}




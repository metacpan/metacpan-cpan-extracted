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
			[-1,-1],[-1],
			[-1,1],[1],
			[1,-1],[1],
			[1,1],[-1]]);

$dataset->save(filename=>'xor.pat');
$dataset->load(filename=>'xor.pat');


my $counter=0;
my $err = 10;
while ($err >.001)
#for (1..1500)
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

print "this should be 1 - ".@{$network->run([-1,1])}."\n";


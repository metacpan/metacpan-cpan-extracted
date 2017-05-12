# example script to build a hopfield net
use strict;
use AI::NNFlex::Hopfield;
use AI::NNFlex::Dataset;

my $network = AI::NNFlex::Hopfield->new();

$network->add_layer(nodes=>2);
$network->add_layer(nodes=>2);

$network->init();

my $dataset = AI::NNFlex::Dataset->new();

$dataset->add([-1, 1, -1, 1]);
$dataset->add([-1, -1, 1, 1]);

$network->learn($dataset);

#my $outputref = $network->run([-1,1,-1,1]);
#my $outputref = $network->run([-1,1,-1,1]);
#my $outputref = $network->run([-1,1,-1,1]);
my $outputref = $network->run([1,-1,1,1]);
my $outputref = $network->run([1,-1,1,1]);
my $outputref = $network->run([1,-1,1,1]);

print @$outputref;

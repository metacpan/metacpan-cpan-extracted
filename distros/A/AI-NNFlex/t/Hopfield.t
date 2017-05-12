# example script to build a hopfield net
use strict;
use AI::NNFlex::Hopfield;
use AI::NNFlex::Dataset;
use Test;


BEGIN{plan tests=>4}
my $matrixpresent = eval("require(Math::Matrix)");
my $matrixabsent = !$matrixpresent;

my $network = AI::NNFlex::Hopfield->new();

skip($matrixabsent,$network);


$network->add_layer(nodes=>2);
$network->add_layer(nodes=>2);

my $result = $network->init();
skip($matrixabsent,$result);

my $dataset = AI::NNFlex::Dataset->new();

$dataset->add([-1, 1, -1, 1]);
$dataset->add([-1, -1, 1, 1]);

skip($matrixabsent,$dataset);

$network->learn($dataset);

my $outputref = $network->run([1,-1,1,1]);

skip($matrixabsent,$outputref);

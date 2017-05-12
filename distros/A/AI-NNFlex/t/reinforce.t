use strict;
use Test;
use AI::NNFlex::Reinforce;
use AI::NNFlex::Dataset;

BEGIN{
	plan tests=>5}

# test create network
my $network = AI::NNFlex::Reinforce->new(randomconnections=>0,
				randomweights=>1,
				learningrate=>.1,
				debug=>[],bias=>1);

ok($network); #test 1
##

# test add layer
my $result = $network->add_layer(	nodes=>2,
			persistentactivation=>0,
			decay=>0.0,
			randomactivation=>0,
			threshold=>0.0,
			activationfunction=>"tanh",
			randomweights=>1);
ok($result); #test 2
##

# Test initialise network
$result = $network->init();
ok($result); #test 3
##

# test create dataset
my $dataset = AI::NNFlex::Dataset->new([
			[0,0],[1,1],
			[0,1],[1,0],
			[1,0],[0,1],
			[1,1],[0,0]]);
ok ($dataset); #test 4
##

# Test a run pass
$result = $dataset->run($network);
ok($result); #test 5
##


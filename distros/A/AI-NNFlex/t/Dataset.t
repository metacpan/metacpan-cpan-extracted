use strict;
use Test;
use AI::NNFlex::Backprop;
use AI::NNFlex::Dataset;

BEGIN{
	plan tests=>12}




# we need a basic network  in place to test the dataset functionality against
# test create network
my $network = AI::NNFlex::Backprop->new(randomconnections=>0,
				randomweights=>1,
				learningrate=>.1,
				debug=>[],bias=>1,
				momentum=>0.6);

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

# test adding an entry
$result = $dataset->add([[1,1],[0,1]]);
ok($result);

# test save
$result = $dataset->save(filename=>'test.pat');
ok ($result);

# test empty dataset
my $dataset2 = AI::NNFlex::Dataset->new();
ok($dataset);

# test load
$result = $dataset2->load(filename=>'test.pat');
ok($result);

#  compare original & loaded dataset
my $comparison;
if (scalar @{$dataset->{'data'}} == scalar @{$dataset2->{'data'}}){$comparison=1}
ok($comparison);

# delete a pair from the dataset
$result = $dataset->delete([4,5]);
ok($result);

# Test a learning pass
my $err = $dataset->learn($network);
ok($err); #test 5
##


# Test a run pass
$result = $dataset->run($network);
ok($result); #test 8
##


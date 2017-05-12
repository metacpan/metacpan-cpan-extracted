package K_test;
use Test::More tests => 35;

use lib "../lib";

use strict;
use warnings;

use_ok ("AI::NeuralNet::Kohonen" => 0.14);
use_ok ("AI::NeuralNet::Kohonen::Node" => 0.12);
use_ok ("AI::NeuralNet::Kohonen::Input");

my ($dir) = $0 =~ /^(.*?)[^\\\/]+$/;

my $net = new AI::NeuralNet::Kohonen;
is($net,undef);

$net = new AI::NeuralNet::Kohonen(
	weight_dim => 2,
	input => [
		[1,2,3]
	],
);
isa_ok( $net->{input}, 'ARRAY');

is( $net->{input}->[0]->[0],1);
is( $net->{input}->[0]->[1],2);
is( $net->{input}->[0]->[2],3);
is( $net->{map_dim_a},19);

$net = new AI::NeuralNet::Kohonen(
	weight_dim => 2,
	input => [
		[1,2,3]
	],
	map_dim_x => 10,
	map_dim_y => 20,
);
is($net->{map_dim_a},15);


# Node test
my $node = new AI::NeuralNet::Kohonen::Node;
is($node,undef) or BAIL_OUT();
$node = new AI::NeuralNet::Kohonen::Node(
	weight => [0.1, 0.6, 0.5],
);
isa_ok( $node, 'AI::NeuralNet::Kohonen::Node');
is( $node->{dim}, 2);
my $input = new AI::NeuralNet::Kohonen::Input(
	dim		=> 2,
	values	=> [1,0,0],
);

is( sprintf("%.2f",$node->distance_from($input)), 1.19);

$net = AI::NeuralNet::Kohonen->new(
	map_dim_x	=> 14,
	map_dim_y	=> 10,
	epoch_end	=> sub {print"."},
	train_end	=> sub {print"\n"},
	epochs		=> 2,
	table		=>
"3
1 0 0 red
0 1 0 green
0 0 1 blue
",
);
isa_ok( $net->{input}, 'ARRAY');
isa_ok( $net->{input}->[0],'AI::NeuralNet::Kohonen::Input');
is( $net->{input}->[0]->{values}->[0],1);
is( $net->{input}->[0]->{values}->[1],0);
is( $net->{input}->[0]->{values}->[2],0);
is( $net->{weight_dim}, 2);
isa_ok( $net->{map}, 'ARRAY');
$net->train;
isa_ok( $net->{map}, 'ARRAY');
my @bmu = $net->get_results();
isa_ok( $bmu[0], 'ARRAY');
isa_ok( $net->{map}->[ 0 ]->[ 0 ], "AI::NeuralNet::Kohonen::Node" );

@bmu = $net->get_results([[0.5,0,0]]);
isa_ok($net->{map}->[ $bmu[0]->[1] ]->[ $bmu[0]->[2] ],
	"AI::NeuralNet::Kohonen::Node"
);
# warn $net->{map}->[ $bmu[1] ]->[ $bmu[2] ];#->get_class;
# Get the nearest class?

{
	my $i=0;
	my $targets = [[1, 0, 0],[0,1,0],[0,0,1]];
	my @bmu = $net->get_results($targets);
	# qerror
	my $qerror=0;
	foreach my $j (0..$net->{weight_dim}){ # loop over weights
		$qerror += $targets->[0]->{values}->[$j]
		- $net->{map}->[$bmu[$i]->[1]]->[$bmu[$i]->[2]]->{weight}->[$j];
	}
	is( $qerror, $net->quantise_error([ [1,0,0] ]));
}


SKIP: {
	skip 'Lost the input file',9;

	# Input file tests\n";
	$net = AI::NeuralNet::Kohonen->new(
		epochs	=> 0,
		input_file => $dir.'ex.dat',
		epoch_end	=> sub {print"."},
		train_end	=> sub {print"\n"},
	);
	isa_ok( $net,'AI::NeuralNet::Kohonen');
	isa_ok( $net->{input}, 'ARRAY');
	is( scalar @{$net->{input}}, 3840);
	is( $net->{map_dim_x}, 19);
	is ($net->{input}->[$#{$net->{input}}]->{values}->[4], 406.918518);
	is( ref $net->{input}->[$#{$net->{input}}]->{values}, 'ARRAY');
	diag "Training on a big file: this is SLOW, sorry\n";
	is($net->train,1);
	my $filename = substr(time,0,8);
	ok($net->save_file($filename),"Saved file as ".$filename);
	ok(unlink($filename),'Unlinked test file '.$filename);
}

sub BAIL_OUT {
	diag "BAIL_OUT:",@_? @_ : "";
	exit;
}


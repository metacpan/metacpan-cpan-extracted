package Visual_and_RGB_test;
use lib "../lib";
use Test::More tests => 14;

my $delay = 1;

use_ok( "AI::NeuralNet::Kohonen" => 0.14 );
use_ok( "AI::NeuralNet::Kohonen::Visual" => 0.3);

diag "# Test 1 - basic confirmations that object-properties work correctly\n";

$net = AI::NeuralNet::Kohonen::Visual->new(
	display			=> 'hex',
	map_dim_x		=> 14,
	map_dim_y		=> 10,
	display_scale 	=> 20,
	epochs 			=> 49,
	show_bmu		=> 1,
	targeting		=> 1,
	table			=>
"3
1 0 0 red
0 1 0 yellow
0 0 1 green
0 1 1 cyan
1 1 0 yellow
1 .5 0 orange
1 .5 1 pink
",
);
isa_ok( $net->{input}, 'ARRAY');
is( $net->{input}->[0]->{values}->[0],1);
is( $net->{input}->[0]->{values}->[1],0);
is( $net->{input}->[0]->{values}->[2],0);
is( $net->{weight_dim}, 2);

$net->train;

diag "Will automatically destroy this window in $delay seconds";
$net->{_mw}->after($delay*1000, sub{ $net->{_mw}->destroy } );

$net->main_loop;
pass;


diag "# Test 2 ... this is *slow*, sorry\n";
$net = AI::NeuralNet::Kohonen::Visual->new(
	display		=> 'hex',
	map_dim	=> 39,
	epochs => 19,
	neighbour_factor => 2,
	targeting	=> 1,
	table=>
"3
1 0 0 red
0 1 0 yellow
0 0 1 blue
0 1 1 cyan
1 1 0 yellow
1 .5 0 orange
1 .5 1 pink
",
);
isa_ok( $net->{input}, 'ARRAY');
is( $net->{input}->[0]->{values}->[0],1);
is( $net->{input}->[0]->{values}->[1],0);
is( $net->{input}->[0]->{values}->[2],0);
is( $net->{weight_dim}, 2);

ok $net->train;


# Find red and display on the training map
diag "# Best matching unit for the colour blue (&#00F)\n";
my $targets = [[0, 0, 1]];
my $bmu = $net->get_results($targets);
$net->plot_map (bmu_x=>$bmu->[1],bmu_y=>$bmu->[2],hicol=>'white');

# $net->main_loop;

# Create an empty map
# and populate with training data

diag "# Plotting results\n";
foreach my $bmu ($net->get_results){
	$net->label_map(@$bmu->[1],@$bmu->[2],"+".@$bmu->[3]);
}


diag "Will automatically destroy this window in $delay seconds";
$net->{_mw}->after($delay*1000, sub{ $net->{_mw}->destroy } );

$net->plot_map;
$net->main_loop;

diag "# Done\n";

# $net->main_loop;

__END__












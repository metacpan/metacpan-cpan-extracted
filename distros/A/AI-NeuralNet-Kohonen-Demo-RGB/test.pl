package RGB_test;
use lib "../../../..";
use Test;
BEGIN { plan test => 12}

use AI::NeuralNet::Kohonen::Demo::RGB;
ok(1,1);

$_ = new AI::NeuralNet::Kohonen;
ok ($_,undef);

$_ = new AI::NeuralNet::Kohonen::Demo::RGB(
	input => [
		[1,2,3]
	],
);
ok( ref $_->{input}, 'ARRAY');
ok( $_->{input}->[0]->[0],1);
ok( $_->{input}->[0]->[1],2);
ok( $_->{input}->[0]->[2],3);


$_ = AI::NeuralNet::Kohonen::Demo::RGB->new(
	map_dim	=> 39,
	epochs => 3,
	table=>
"R G B
1 0 0
0 1 0
0 0 1
",
);
ok( ref $_->{input}, 'ARRAY');
ok( $_->{input}->[0]->[0],1);
ok( $_->{input}->[0]->[1],0);
ok( $_->{input}->[0]->[2],0);
ok( $_->{weight_dim}, 2);

$_->train;

$_ = AI::NeuralNet::Kohonen::Demo::RGB->new(
	display_scale => 10,
	display	=> 'hex',
	map_dim	=> 39,
	epochs => 9,
	table=>
"R G B
1 0 0
0 1 0
0 0 1
",
);
ok( ref $_->{input}, 'ARRAY');
ok( $_->{input}->[0]->[0],1);
ok( $_->{input}->[0]->[1],0);
ok( $_->{input}->[0]->[2],0);
ok( $_->{weight_dim}, 2);

$_->train;

ok(1,1);

__END__


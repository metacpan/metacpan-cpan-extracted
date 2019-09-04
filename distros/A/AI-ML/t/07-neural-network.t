#!perl

use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use AI::ML::NeuralNetwork;
use Math::Lapack;
use Data::Dumper;


Math::Lapack->seed_rng(0);

my $x = Math::Lapack::Matrix::read_csv("t/x.csv");
my $y = Math::Lapack::Matrix::read_csv("t/y.csv");

my $NN = AI::ML::NeuralNetwork->new(
				[
								2,
								{func => "tanh", units => 3}, 
								1
				],
                n => 5000,
                alpha => 1.2

);

$NN->{"l1"}{w} = Math::Lapack::Matrix::read_csv("t/w1.csv");
$NN->{"l2"}{w} = Math::Lapack::Matrix::read_csv("t/w2.csv");
my $pred = Math::Lapack::Matrix::read_csv("t/pred-nn.csv");

$NN->train($x, $y);

$NN->prediction($x);

is($NN->{yatt}->rows, $pred->rows, "Right number of rows");
is($NN->{yatt}->columns, $pred->columns, "Right number of columns");

for (0..$NN->{yatt}->columns-1) {
    is( $NN->{yatt}->get_element(0, $_),
        $pred->get_element(0, $_),
        "Right element on 0,$_"
    );
}

_float($NN->accuracy($y), 0.98, "Right accuracy");
_float($NN->precision($y), 0.970588235294118, "Right precision");
_float($NN->recall($y), .99, "Right recall");
_float($NN->f1($y), 0.98019801980198, "Right F1");

done_testing();

sub _float {
  my ($a, $b, $c) = @_;
	is($a, float($b, tolerance => 0.1), $c);
}

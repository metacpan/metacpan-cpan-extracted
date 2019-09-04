#!perl

use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use Math::Lapack;
use AI::ML::LogisticRegression;

Math::Lapack->seed_rng(0);

my $x = Math::Lapack::Matrix::read_csv("t/logistic.csv", col_range =>[0,2]);
my $y = Math::Lapack::Matrix::read_csv("t/logistic.csv", col => 3);


is($x->rows, 306, "Right number of rows");
is($y->rows, 306, "Right number of rows");
is($x->columns, 3, "Right number of cols");
is($y->columns, 1, "Right number of cols");


is($x->get_element(0,0),30, "Right element 0,0 of x");
is($x->get_element(1,2),3, "Right element 1,2 of x");
is($x->get_element(3,1),59, "Right element 3,1 of x");
is($x->get_element(2,2),0, "Right element 2,2 of x");
is($y->get_element(3,0),1, "Right element 3,0 of y");
is($y->get_element(7,0),2, "Right element 7,0 of y");

$x->norm_std_deviation();
$y = $y - 1;

my $m = AI::ML::LogisticRegression->new(
				n 		=> 10000,
				alpha => 0.5,
				cost 	=> "../../logistcost.png"
);


$m->train($x, $y);
my $thetas = $m->{thetas};
_float($thetas->get_element(0,0), -1.07661735,"Right vale of theta 0,0");
_float($thetas->get_element(1,0), 0.21463009,"Right vale of theta 1,0");
_float($thetas->get_element(2,0), -0.03173973,"Right vale of theta 2,0");
_float($thetas->get_element(3,0), 0.63483062,"Right vale of theta 3,0");


$m->prediction($x);
_float($m->accuracy($y), 0.7483660130718954, "Right value of accuracy");
_float($m->precision($y), 0.5833333333333334, "Right value of precision");
_float($m->recall($y), 0.1728395061728395, "Right value of recall");
_float($m->f1($y), 0.26666666666666666, "Right value of f1");



#print STDERR "Accuracy: $acc\n";

#print STDERR "Precison: $prec\n";

#print STDERR "Recall: $rec\n";

#print STDERR "F1: $f1\n";







my $n = AI::ML::LogisticRegression->new(
				n 		=> 10000,
				alpha => 0.5,
				cost 	=> "../../logistcost_reg.png",
				reg 	=> 2
);


$n->train($x, $y);
$thetas = $n->{thetas};
_float($thetas->get_element(0,0), -1.07368839, "Right vale of theta 0,0");
_float($thetas->get_element(1,0), 0.204271, "Right vale of theta 1,0");
_float($thetas->get_element(2,0), -0.02933972, "Right vale of theta 2,0");
_float($thetas->get_element(3,0), 0.60950995, "Right vale of theta 3,0");


$n->prediction($x);
_float($n->accuracy($y), 0.7450980392156863, "Right value of accuracy");
_float($n->precision($y), 0.5652173913043478, "Right value of precision");
_float($n->recall($y), 0.16049382716049382, "Right value of recall");
_float($n->f1($y), .25, "Right value of f1");


done_testing;

sub _float {
    my ($a, $b, $c) = @_;
	is($a, float($b, tolerance => 0.01), $c);
}

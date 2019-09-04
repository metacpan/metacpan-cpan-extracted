#!perl

use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use AI::ML::Expr;

use Data::Dumper;


my $m = Math::Lapack::Matrix->new(
				[ 
					[0, 0.002, 3, 4, 7.333, -.00008, -2.03456, 9, 100.3456, -300] 
				]
);

is($m->rows, 1, "Right number of rows");
is($m->columns, 10, "Right number of columns");

#Test Sigmoid
my $a = sigmoid($m);
_float($a->get_element(0,0), 0.5, "Element correct at 0,0");
_float($a->get_element(0,1), 5.005e-1, "Element correct at 0,1");
_float($a->get_element(0,2), 9.52574127e-001, "Element correct at 0,2");
_float($a->get_element(0,3), 9.82013790e-001, "Element correct at 0,3");
_float($a->get_element(0,4), 9.99346817e-001, "Element correct at 0,4");
_float($a->get_element(0,5), 4.99980000e-001, "Element correct at 0,5");
_float($a->get_element(0,6), 1.15621829e-001, "Element correct at 0,6");
_float($a->get_element(0,7), 9.99876605e-001, "Element correct at 0,7");
_float($a->get_element(0,8), 1, "Element correct at 0,8");
_float($a->get_element(0,9), 5.14820022e-131, "Element correct at 0,9");

#Test Derivative of Sigmoid
$a = d_sigmoid($m);
_float($a->get_element(0,0), 2.50000000e-001, "Element correct at 0,0");
_float($a->get_element(0,1), 2.49999750e-001, "Element correct at 0,1");
_float($a->get_element(0,2), 4.51766597e-002, "Element correct at 0,2");
_float($a->get_element(0,3), 1.76627062e-002, "Element correct at 0,3");
_float($a->get_element(0,4), 6.52756239e-004, "Element correct at 0,4");
_float($a->get_element(0,5), 2.50000000e-001, "Element correct at 0,5");
_float($a->get_element(0,6), 1.02253421e-001, "Element correct at 0,6");
_float($a->get_element(0,7), 1.23379350e-004, "Element correct at 0,7");
_float($a->get_element(0,8), 0, "Element correct at 0,8");
_float($a->get_element(0,9), 5.14820022e-131, "Element correct at 0,9");

#Test Relu
my $b = relu($m);
_float($b->get_element(0,0), 0, "Element correct at 0,0");
_float($b->get_element(0,1), 2.000000e-03, "Element correct at 0,1");
_float($b->get_element(0,2), 3, "Element correct at 0,2");
_float($b->get_element(0,3), 4, "Element correct at 0,3");
_float($b->get_element(0,4), 7.333000e+00, "Element correct at 0,4");
_float($b->get_element(0,5), 0, "Element correct at 0,5");
_float($b->get_element(0,6), 0, "Element correct at 0,6");
_float($b->get_element(0,7), 9, "Element correct at 0,7");
_float($b->get_element(0,8), 1.003456e+02, "Element correct at 0,8");
_float($b->get_element(0,9), 0, "Element correct at 0,9");

#Test derivative of Relu
$b = d_relu($m);
_float($b->get_element(0,0), 1, "Element correct at 0,0");
_float($b->get_element(0,1), 1, "Element correct at 0,1");
_float($b->get_element(0,2), 1, "Element correct at 0,2");
_float($b->get_element(0,3), 1, "Element correct at 0,3");
_float($b->get_element(0,4), 1, "Element correct at 0,4");
_float($b->get_element(0,5), 0, "Element correct at 0,5");
_float($b->get_element(0,6), 0, "Element correct at 0,6");
_float($b->get_element(0,7), 1, "Element correct at 0,7");
_float($b->get_element(0,8), 1, "Element correct at 0,8");
_float($b->get_element(0,9), 0, "Element correct at 0,9");

#Test leaky Relu
my $c = lrelu($m, .001);
_float($c->get_element(0,0), 0, "Element correct at 0,0");
_float($c->get_element(0,1), 2.000000e-03, "Element correct at 0,1");
_float($c->get_element(0,2), 3.000000e+00, "Element correct at 0,2");
_float($c->get_element(0,3), 4.000000e+00, "Element correct at 0,3");
_float($c->get_element(0,4), 7.333000e+00, "Element correct at 0,4");
_float($c->get_element(0,5), -8.000000e-08, "Element correct at 0,5");
_float($c->get_element(0,6), -2.034560e-03, "Element correct at 0,6");
_float($c->get_element(0,7), 9.000000e+00, "Element correct at 0,7");
_float($c->get_element(0,8), 1.003456e+02, "Element correct at 0,8");
_float($c->get_element(0,9), -3.000000e-01, "Element correct at 0,9");

#Test derivative of leaky Relu
$c = d_lrelu($m, .001);
_float($c->get_element(0,0), 1, "Element correct at 0,0");
_float($c->get_element(0,1), 1, "Element correct at 0,1");
_float($c->get_element(0,2), 1, "Element correct at 0,2");
_float($c->get_element(0,3), 1, "Element correct at 0,3");
_float($c->get_element(0,4), 1, "Element correct at 0,4");
_float($c->get_element(0,5), .001, "Element correct at 0,5");
_float($c->get_element(0,6), .001, "Element correct at 0,6");
_float($c->get_element(0,7), 1, "Element correct at 0,7");
_float($c->get_element(0,8), 1, "Element correct at 0,8");
_float($c->get_element(0,9), .001, "Element correct at 0,9");

# Test tanh
my $d = tanh($m);
_float($d->get_element(0,0), 0, "Element correct at 0,0");
_float($d->get_element(0,1), 1.99999733e-03, "Element correct at 0,1");
_float($d->get_element(0,2), 9.95054754e-01, "Element correct at 0,2");
_float($d->get_element(0,3), 9.99329300e-01, "Element correct at 0,3");
_float($d->get_element(0,4), 9.99999146e-01, "Element correct at 0,4");
_float($d->get_element(0,5), -7.99999998e-05, "Element correct at 0,5");
_float($d->get_element(0,6), -9.66389636e-01, "Element correct at 0,6");
_float($d->get_element(0,7), 9.99999970e-01, "Element correct at 0,7");
_float($d->get_element(0,8), 1, "Element correct at 0,8");
_float($d->get_element(0,9), -1, "Element correct at 0,9");

#Test derivative of tanh
$d = d_tanh($m);
_float($d->get_element(0,0), 1.00000000e+00, "Element correct at 0,0");
_float($d->get_element(0,1), 9.99996000e-01, "Element correct at 0,1");
_float($d->get_element(0,2), 9.86603717e-03, "Element correct at 0,2");
_float($d->get_element(0,3), 1.34095068e-03, "Element correct at 0,3");
_float($d->get_element(0,4), 1.70882169e-06, "Element correct at 0,4");
_float($d->get_element(0,5), 9.99999994e-01, "Element correct at 0,5");
_float($d->get_element(0,6), 6.60910712e-02, "Element correct at 0,6");
_float($d->get_element(0,7), 6.09199171e-08, "Element correct at 0,7");
_float($d->get_element(0,8), 0, "Element correct at 0,8");
_float($d->get_element(0,9), 0, "Element correct at 0,9");


# Test softmax
my $e =  Math::Lapack::Matrix->new(
               [
                [1, 2, 1],  # sample 1
                [2, 4, 2],  # sample 1
                [3, 5, 3],  # sample 2
                [6, 6, 6]
            ]);


my $soft = softmax($e);

is($e->rows, 4, "Right number of rows - softmax");
is($e->columns, 3, "Right number of cols - softmax");

# prob of first col
_float($soft->get_element(0,0), 0.00626879, "Element correct at 0,0");
_float($soft->get_element(1,0), 0.01704033, "Element correct at 1,0");
_float($soft->get_element(2,0), 0.04632042, "Element correct at 2,0");
_float($soft->get_element(3,0), 0.93037047, "Element correct at 3,0");

# prob of second col
_float($soft->get_element(0,1), 0.01203764, "Element correct at 0,1");
_float($soft->get_element(1,1), 0.08894682, "Element correct at 1,1");
_float($soft->get_element(2,1), 0.24178252, "Element correct at 2,1");
_float($soft->get_element(3,1), 0.65723302, "Element correct at 3,1");

#prob of third col
_float($soft->get_element(0,2), 0.00626879, "Element correct at 0,2");
_float($soft->get_element(1,2), 0.01704033, "Element correct at 1,2");
_float($soft->get_element(2,2), 0.04632042, "Element correct at 2,2");
_float($soft->get_element(3,2), 0.93037047, "Element correct at 3,2");


done_testing;

sub _float {
  my ($a, $b, $c) = @_;
	is($a, float($b, tolerance => 0.00001), $c);
}

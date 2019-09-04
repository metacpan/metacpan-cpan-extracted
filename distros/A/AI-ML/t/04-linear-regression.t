#!perl

use Test2::V0;

use Math::Lapack::Matrix;
use AI::ML::LinearRegression;


my $x = Math::Lapack::Matrix->new([[12.39999962],[14.30000019],[14.5],[14.89999962],[16.10000038],[16.89999962],[16.5],[15.39999962],[17],[17.89999962],[18.79999924],[20.29999924],[22.39999962],[19.39999962],[15.5],[16.70000076],[17.29999924],[18.39999962],[19.20000076],[17.39999962],[19.5],[19.70000076],[21.20000076]]);

my $y = Math::Lapack::Matrix->new([[11.19999981],[12.5],[12.69999981],[13.10000038],[14.10000038],[14.80000019],[14.39999962],[13.39999962],[14.89999962],[15.60000038],[16.39999962],[17.70000076],[19.60000038],[16.89999962],[14],[14.60000038],[15.10000038],[16.10000038],[16.79999924],[15.19999981],[17],[17.20000076],[18.60000038]]);

my $m = AI::ML::LinearRegression->new(plot => "../../plot.png");

$m->train($x, $y);

my $t = $m->{thetas};

is($t->rows, 2, "Right number of rows");
is($t->columns, 1, "Right number of columns");
_float($t->get_element(0,0), 0.43458449, "Normal Equation - Right value of theta 0,0");
_float($t->get_element(1,0), 0.85114404, "Normal Equation - Right value of theta 1,0");

my $m1 = AI::ML::LinearRegression->new(
    cost     => "../../cost1.png",
    gradient => "foo",
    plot     => "../../plot1.png",
    n        => 50,
    alpha    => 0.001
);


$m1->train($x, $y);
is($m1->{thetas}->rows, 2, "Right number of rows");
is($m1->{thetas}->columns, 1, "Right number of columns");
_float($m1->{thetas}->get_element(0,0), 0.86412871, "Normal Equation - Right value of theta 0,0");
_float($m1->{thetas}->get_element(1,0), 0.8269897, "Normal Equation - Right value of theta 1,0");


my $n = AI::ML::LinearRegression->new(
                                             lambda   => 1,
                                             cost     => "../../cost2.png",
                                             gradient => "foo",
                                             plot     => "../../plot2.png",
                                             n        => 50,
                                             alpha    => 0.001);
$n->train($x, $y);
is($n->{thetas}->rows, 2, "Right number of rows");
is($n->{thetas}->columns, 1, "Right number of columns");

_float($n->{thetas}->get_element(0,0), 0.78473628, "Normal Equation - Right value of theta 0,0");
_float($n->{thetas}->get_element(1,0), 0.83133813, "Normal Equation - Right value of theta 1,0");
### FIXME: if the tests generate files, you should test them.
##         and delete them afterwads

done_testing();

sub _float {
    my ($a, $b, $c) = @_;
    is($a, float($b, tolerance => 0.000001), $c);
}

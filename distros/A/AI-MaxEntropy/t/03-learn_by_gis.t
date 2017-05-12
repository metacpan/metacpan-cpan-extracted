use strict;
use warnings;

use Test::More tests => 3;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

###
NAME 'Load the module';
BEGIN { use_ok 'AI::MaxEntropy' }

my ($lambda, $d_lambda, $p1_f, $n);
my $zero = 1e-5;
my $me = AI::MaxEntropy->new(); 
$me->see(['round', 'smooth', 'red'] => 'apple' => 2);
$me->see(['long', 'smooth', 'yellow'] => 'banana' => 3);
$me->{algorithm}->{type} = 'gis';

###
NAME 'The first iteration';
$me->{algorithm}->{progress_cb} =
    sub { ($lambda, $d_lambda) = ($_[1], $_[2]); 1 };
$me->learn;
$p1_f = [
    2 * (exp(0) / (exp(0) + exp(0))),
    2 * (exp(0) / (exp(0) + exp(0))) + 3 * (exp(0) / (exp(0) + exp(0))),
    2 * (exp(0) / (exp(0) + exp(0))),
    3 * (exp(0) / (exp(0) + exp(0))),
    3 * (exp(0) / (exp(0) + exp(0))),
    2 * (exp(0) / (exp(0) + exp(0))),
    2 * (exp(0) / (exp(0) + exp(0))) + 3 * (exp(0) / (exp(0) + exp(0))),
    2 * (exp(0) / (exp(0) + exp(0))),
    3 * (exp(0) / (exp(0) + exp(0))),
    3 * (exp(0) / (exp(0) + exp(0)))
];
delta_ok
[
    $lambda,
    $d_lambda
],
[
    [
        (1.0 / 3) * log(2 / $p1_f->[0]),
	(1.0 / 3) * log(2 / $p1_f->[1]),
	(1.0 / 3) * log(2 / $p1_f->[2]),
	(1.0 / 3) * log($zero / $p1_f->[3]),
	(1.0 / 3) * log($zero / $p1_f->[4]),
	(1.0 / 3) * log($zero / $p1_f->[5]),
	(1.0 / 3) * log(3 / $p1_f->[6]),
	(1.0 / 3) * log($zero / $p1_f->[7]),
	(1.0 / 3) * log(3 / $p1_f->[8]),
	(1.0 / 3) * log(3 / $p1_f->[9])
    ],
    [
        (1.0 / 3) * log(2 / $p1_f->[0]),
	(1.0 / 3) * log(2 / $p1_f->[1]),
	(1.0 / 3) * log(2 / $p1_f->[2]),
	(1.0 / 3) * log($zero / $p1_f->[3]),
	(1.0 / 3) * log($zero / $p1_f->[4]),
	(1.0 / 3) * log($zero / $p1_f->[5]),
	(1.0 / 3) * log(3 / $p1_f->[6]),
	(1.0 / 3) * log($zero / $p1_f->[7]),
	(1.0 / 3) * log(3 / $p1_f->[8]),
	(1.0 / 3) * log(3 / $p1_f->[9])
    ]
],
$__;

###
NAME 'The second iteration';
my @l = @$lambda;
$me->{algorithm}->{progress_cb} =
    sub { ($lambda, $d_lambda) = ($_[1], $_[2]); $n++; $n >= 2 ? 1 : 0 };
$me->learn;
my $p0 = exp($l[0] + $l[1] + $l[2]) + exp($l[5] + $l[6] + $l[7]);
my $p0_0 = exp($l[0] + $l[1] + $l[2]) / $p0;
my $p0_1 = exp($l[5] + $l[6] + $l[7]) / $p0;
my $p1 = exp($l[6] + $l[8] + $l[9]) + exp($l[1] + $l[3] + $l[4]);
my $p1_0 = exp($l[1] + $l[3] + $l[4]) / $p1;
my $p1_1 = exp($l[6] + $l[8] + $l[9]) / $p1;
$p1_f = [
    2 * $p0_0,
    2 * $p0_0 + 3 * $p1_0,
    2 * $p0_0,
    3 * $p1_0,
    3 * $p1_0,
    2 * $p0_1,
    2 * $p0_1 + 3 * $p1_1,
    2 * $p0_1,
    3 * $p1_1,
    3 * $p1_1
];
delta_ok
[
    $lambda,
    $d_lambda
],
[
    [
        $l[0] + (1.0 / 3) * log(2 / $p1_f->[0]),
	$l[1] + (1.0 / 3) * log(2 / $p1_f->[1]),
	$l[2] + (1.0 / 3) * log(2 / $p1_f->[2]),
	$l[3] + (1.0 / 3) * log($zero / $p1_f->[3]),
	$l[4] + (1.0 / 3) * log($zero / $p1_f->[4]),
	$l[5] + (1.0 / 3) * log($zero / $p1_f->[5]),
	$l[6] + (1.0 / 3) * log(3 / $p1_f->[6]),
	$l[7] + (1.0 / 3) * log($zero / $p1_f->[7]),
	$l[8] + (1.0 / 3) * log(3 / $p1_f->[8]),
	$l[9] + (1.0 / 3) * log(3 / $p1_f->[9])
    ],
    [
        (1.0 / 3) * log(2 / $p1_f->[0]),
	(1.0 / 3) * log(2 / $p1_f->[1]),
	(1.0 / 3) * log(2 / $p1_f->[2]),
	(1.0 / 3) * log($zero / $p1_f->[3]),
	(1.0 / 3) * log($zero / $p1_f->[4]),
	(1.0 / 3) * log($zero / $p1_f->[5]),
	(1.0 / 3) * log(3 / $p1_f->[6]),
	(1.0 / 3) * log($zero / $p1_f->[7]),
	(1.0 / 3) * log(3 / $p1_f->[8]),
	(1.0 / 3) * log(3 / $p1_f->[9])
    ]
],
$__;

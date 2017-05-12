use strict;
use warnings;

use Test::More tests => 4;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

###
NAME 'Preparation for the following tests';
use Algorithm::LBFGS;
my $o = Algorithm::LBFGS->new;
ok 1,
$__;

###
NAME 'A simple optimization (one dimension)';
# f(x) = x^2
{
    my $lbfgs_eval = sub {
        my $x = shift;
        my $f = $x->[0] ** 2;
        my $g = [ 2 * $x->[0] ];
        return ($f, $g);
    };
    my $x1 = $o->fmin($lbfgs_eval, [6]);
    delta_ok $x1, [0],
    $__;
}

###
NAME 'Another simple optimization (two dimensions)';
# f(x1, x2) = x1^2 / 2 + x2^2 / 3
{
    my $lbfgs_eval = sub {
        my $x = shift;
        my $f = $x->[0] ** 2 / 2 + $x->[1] ** 2 / 3;
        my $g = [$x->[0], 2 * $x->[1] / 3];
        return ($f, $g);
    };
    my $x1 = $o->fmin($lbfgs_eval, [5, 5]);
    delta_ok $x1, [0, 0],
    $__;
}

###
NAME 'A high dimension optimization (100,000 dimensions)';
# f(x1, x2, ..., x100000) = (x1 - 2)^2 + (x2 + 3)^2 + x3^2 + ... + x100000^2
{
    my $dim = 100000;
    my $lbfgs_eval = sub {
        my $i;
        my $x = shift;
        my $f = ($x->[0] - 2) ** 2 + ($x->[1] + 3) ** 2;
        for ($i = 2; $i < $dim; $i++) { $f += $x->[$i] * $x->[$i] }
        my $g = [ 2 * $x->[0] - 4, 2 * $x->[1] + 6 ];
        for ($i = 2; $i < $dim; $i++) { $g->[$i] = 2 * $x->[$i] }
        return ($f, $g);
    };
    my $x0 = [];
    for (my $i = 0; $i < $dim; $i++) { $x0->[$i] = 0.5 }
    my $x1 = $o->fmin($lbfgs_eval, $x0);
    my $x1_expected = [];
    $x1_expected->[0] = 2;
    $x1_expected->[1] = -3;
    for (my $i = 2; $i < $dim; $i++) { $x1_expected->[$i] = 0 }
    delta_ok $x1, $x1_expected,
    $__;
}


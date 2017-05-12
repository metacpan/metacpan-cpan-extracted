use strict;
use warnings;

use Test::More tests => 5;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

###
NAME 'Load the module';
BEGIN { use_ok 'AI::MaxEntropy' }

my $me = AI::MaxEntropy->new(smoother => {}); 
$me->see(['round', 'smooth', 'red'] => 'apple' => 2);
$me->see(['long', 'smooth', 'yellow'] => 'banana' => 3);
$me->cut(0);
$me->_cache;

###
NAME 'Negative log likelihood calculation (lambda = all 0)';
my ($f, $g) = AI::MaxEntropy::_neg_log_likelihood(
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], undef, $me
);
delta_ok
[
    $f,
    $g
],
[
    - (2 * log(0.5) + 3 * log(0.5)),
    [
	- ((1 - 0.5) * 2 + 0 * 3),
	- ((1 - 0.5) * 2 + (0 - 0.5) * 3),
	- ((1 - 0.5) * 2 + 0 * 3),
        - (0 * 2 + (0 - 0.5) * 3),
	- (0 * 2 + (0 - 0.5) * 3),
	- ((0 - 0.5) * 2 + 0 * 3),
	- ((0 - 0.5) * 2 + (1 -0.5) * 3),
	- ((0 - 0.5) * 2 + 0 * 3),
	- (0 * 2 + (1 - 0.5) * 3),
	- (0 * 2 + (1 - 0.5) * 3)
    ]
],
$__;

###
NAME 'Negative log likelihood calculation (lambda = random .1 and 0)';
($f, $g) = AI::MaxEntropy::_neg_log_likelihood(
    [.1, .1, 0, 0, 0, .1, .1, 0, 0, .1], undef, $me
);
delta_ok
[
    $f,
    $g
],
[
    - (log(exp(.1) / (2 * exp(.1))) * 2 +
       log(exp(.2) / (exp(.1) + exp(.2))) * 3),
    [
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3),
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 
	   (0 - exp(.1) / (exp(.1) + exp(.2))) * 3),
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3),
        - (0 * 2 + (0 - exp(.1) / (exp(.1) + exp(.2))) * 3),
	- (0 * 2 + (0 - exp(.1) / (exp(.1) + exp(.2))) * 3),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 +
	   (1 - exp(.2) / (exp(.1) + exp(.2))) * 3),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3),
	- (0 * 2 + (1 - exp(.2) / (exp(.1) + exp(.2))) * 3),
	- (0 * 2 + (1 - exp(.2) / (exp(.1) + exp(.2))) * 3)
    ]
],
$__;

###
NAME 'Negative log likelihood calculation (with Gaussian smoother)';
$me->{smoother} = { type => 'gaussian', sigma => .5 };
($f, $g) = AI::MaxEntropy::_neg_log_likelihood(
    [0, 0, .1, .1, 0, 0, 0, .1, .1, .1], undef, $me
);
delta_ok
[
    $f,
    $g
],
[
    - (log(exp(.1) / (2 * exp(.1))) * 2 +
       log(exp(.2) / (exp(.1) + exp(.2))) * 3 -
       (5 * .1 ** 2) / (2 * .5 ** 2)),
    [
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3 - 0 / .5 ** 2),
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 
	   (0 - exp(.1) / (exp(.1) + exp(.2))) * 3 - 0 / .5 ** 2),
	- ((1 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3 - .1 / .5 ** 2),
        - (0 * 2 + (0 - exp(.1) / (exp(.1) + exp(.2))) * 3 - .1 / .5 ** 2),
	- (0 * 2 + (0 - exp(.1) / (exp(.1) + exp(.2))) * 3 - 0 / .5 ** 2),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3 - 0 / .5 ** 2),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 +
	   (1 - exp(.2) / (exp(.1) + exp(.2))) * 3 - 0 / .5 ** 2),
	- ((0 - exp(.1) / (2 * exp(.1))) * 2 + 0 * 3 - .1 / .5 ** 2),
	- (0 * 2 + (1 - exp(.2) / (exp(.1) + exp(.2))) * 3 - .1 / .5 ** 2),
	- (0 * 2 + (1 - exp(.2) / (exp(.1) + exp(.2))) * 3 - .1 / .5 ** 2)
    ]
],
$__;

$me->_free_cache;

###
NAME 'Model object construction';
$me->{smoother} = {};
my $model = $me->learn;
is_deeply
[
    $model->{x_bucket},
    $model->{y_bucket},
    $model->{x_list},
    $model->{y_list},
    $model->{x_num},
    $model->{y_num},
    $model->{f_num},
    $model->{f_map}
],
[
    { round => 0, smooth => 1, red => 2, long => 3, yellow => 4 },
    { apple => 0, banana => 1 },
    [ 'round', 'smooth', 'red', 'long', 'yellow' ],
    [ 'apple', 'banana' ],
    5,
    2,
    10,
    [
        [0, 1, 2, 3, 4],
	[5, 6, 7, 8, 9]
    ]
],
$__;


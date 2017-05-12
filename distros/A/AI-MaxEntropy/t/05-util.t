use strict;
use warnings;

use Test::More tests => 8;
use Test::Number::Delta within => 1e-5;


my $__;
sub NAME { $__ = shift };

###
NAME 'Load the module';
BEGIN { use_ok 'AI::MaxEntropy::Util', qw(:all) }

###
NAME 'traverse_partially x-x-x';
my $a = [1, 2, 3, 4, 5];
my $b = [];
traverse_partially { push @$b, $_ } $a, 'x-x-x';
is_deeply $b, [1, 3, 5],
$__;

###
NAME 'traverse_partially o-o-o => o';
$a = [1, 2, 3, 4, 5, 6];
$b = [];
traverse_partially { push @$b, $_ } $a, 'o-o-o' => 'o';
is_deeply $b, [1, 3, 5, 6],
$__;

###
NAME 'map_partially o-o => o';
$a = [1, 2, 3, 4, 5, 6];
$b = map_partially { $_ + 1 } $a, 'o-o' => 'o';
is_deeply $b, [2, 3, 6, 7],
$__;

###
NAME 'train_and_test xxo';
require AI::MaxEntropy;
my ($me, $samples, $result, $model);
$me = AI::MaxEntropy->new;
$samples = [
    [['a', 'b', 'c'] => 'x'],
    [['e', 'f'] => 'z'],
    [['e'] => 'z']
];
($result, $model) = train_and_test($me, $samples, 'xxo');
is_deeply
$result,
[
    [[['e'] => 'z'] => 'z']
],
$__;

###
NAME 'train_and_test xxxxo';
$me->forget_all;
$samples = [
    [['a', 'b'] => 'x'],
    [['c', 'd'] => 'y'],
    [['i', 'j'] => 'z'],
    [['p', 'q'] => 'xx'],
    [['a'] => 'x'],
    [['c'] => 'x' => 2]
];
($result, $model) = train_and_test($me, $samples, 'xxxxo');
is_deeply
$result,
[
    [[['a'] => 'x'] => 'x'],
    [[['c'] => 'x' => 2] => 'y']
],
$__;

###
NAME 'precision';
delta_ok precision($result), 1 / 3,
$__;

###
NAME 'recall of x';
delta_ok recall($result, 'x'), 1 / 3,
$__;


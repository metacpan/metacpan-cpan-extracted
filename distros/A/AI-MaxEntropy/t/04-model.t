use strict;
use warnings;

use Test::More tests => 5;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

###
NAME 'Load AI::MaxEntropy';
BEGIN { use_ok 'AI::MaxEntropy' }

###
NAME 'Load AI::MaxEntropy::Model';
BEGIN { use_ok 'AI::MaxEntropy::Model' }

my $me = AI::MaxEntropy->new; 
$me->see(['round', 'smooth', 'red'] => 'apple' => 2);
$me->see(['long', 'smooth', 'yellow'] => 'banana' => 3);

###
NAME 'Predict with model - LBFGS';
my $model = $me->learn;
is_deeply
[
    $model->predict(['round']),
    $model->predict(['red']),
    $model->predict(['long']),
    $model->predict(['yellow']),
    $model->predict(['smooth']),
    $model->predict(['round', 'smooth']),
    $model->predict(['red', 'long']),
    $model->predict(['red', 'yellow']),
],
[
    'apple',
    'apple',
    'banana',
    'banana',
    'banana',
    'apple',
    'banana',
    'banana'
],
$__;

###
NAME 'Predict with model - GIS';
$me->{algorithm}->{type} = 'gis';
$model = $me->learn;
is_deeply
[
    $model->predict(['round']),
    $model->predict(['red']),
    $model->predict(['long']),
    $model->predict(['yellow']),
    $model->predict(['smooth']),
    $model->predict(['round', 'smooth']),
    $model->predict(['red', 'long']),
    $model->predict(['red', 'yellow']),
],
[
    'apple',
    'apple',
    'banana',
    'banana',
    'banana',
    'apple',
    'banana',
    'banana'
],
$__;

###
NAME 'Model writing and loading';
$model->save('test_model');
my $model1 = AI::MaxEntropy::Model->new('test_model');
unlink 'test_model';
is_deeply $model, $model1,
$__;

use strict;
use warnings;

use Test::More tests => 6;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

###
NAME 'Load the module';
use_ok 'Algorithm::LBFGS',
$__;

###
NAME 'Create a L-BFGS optimizer';
my $o = Algorithm::LBFGS->new;
ok $o,
$__;

###
NAME 'Default parameters - 1';
delta_ok
[
    $o->get_param('epsilon'),
    $o->get_param('min_step'),
    $o->get_param('max_step'),
    $o->get_param('ftol'),
    $o->get_param('gtol'),
    $o->get_param('orthantwise_c')
],
[
    1e-5,
    1e-20,
    1e+20,
    1e-4,
    0.9,
    0.0
],
$__;

###
NAME 'Default parameters - 2';
is_deeply
[
    $o->get_param('m'),
    $o->get_param('max_iterations'),
    $o->get_param('max_linesearch')
],
[
    6,
    0,
    20
],
$__;

###
NAME 'Create a L-BFGS optimizer by customized parameters';
$o = Algorithm::LBFGS->new(gtol => 1.0, epsilon => 1e-6);
delta_ok
[
    $o->get_param('gtol'),
    $o->get_param('epsilon')
],
[
    1.0,
    1e-6
],
$__;

###
NAME 'Modify parameter';
$o->set_param(m => 4);
is $o->get_param('m'), 4,
$__;


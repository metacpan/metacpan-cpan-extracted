#?/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t = Data::Transfigure->bare();
$t->add_transfigurators(qw(Data::Transfigure::Tree::Merge));

my $h = {a => 1, b => 2, c => 3};

is($t->transfigure($h), {a => 1, b => 2, c => 3}, 'no change');

$h = {"a%" => 1};

is($t->transfigure($h), {'a%' => 1}, 'not a hashref: no change');

$h = {a => 1, b => {c => 3}};

is($t->transfigure($h), {a => 1, b => {c => 3}}, 'no sigil: no change');

$h = {a => 1, "b%" => {c => 3}};

is($t->transfigure($h), {a => 1, c => 3}, 'simple merge');

$h = {a => 1, "b%" => {a => 3}};

is($t->transfigure($h), {a => 3}, 'overwrite merge');

$h = {'a%' => {'b%' => {c => 1, d => 2}}};

is($t->transfigure($h), {c => 1, d => 2}, 'deep merge');


done_testing;

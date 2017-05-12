#! perl

use strict;
use warnings;

use Test::More tests => 1;

use Data::Transpose;
use Data::Dumper;

my ($fsub, $tp, $f, $output);

$fsub = sub {
    return $_[0] * 2;
};

$tp = Data::Transpose->new;
$f = $tp->field('foo');
$f->filter($fsub);
$output = $tp->transpose({foo => 1});

ok(exists $output->{foo} && $output->{foo} == 2,
   'simple filter sub')
    || diag "Transpose output: " . Dumper($output);

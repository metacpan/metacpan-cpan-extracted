#! perl

use strict;
use warnings;

use Test::More tests => 2;

use Data::Transpose;
use Data::Dumper;

my ($tp, $f, $output);

$tp = Data::Transpose->new;
$f = $tp->field('foo');
$f->target('bar');
$output = $tp->transpose({foo => 6});

ok(exists $output->{bar} && $output->{bar} == 6,
   'simple transpose test foo => bar')
    || diag "Transpose output: " . Dumper($output);

my $foo = Foo->new(foo => 6);

$output = $tp->transpose_object($foo);

ok(exists $output->{bar} && $output->{bar} == 6,
   'simple object transpose test foo => bar')
    || diag "Transpose output: " . Dumper($output);

package Foo;

use Moo;

has foo => (
    is => 'ro',
);

1;

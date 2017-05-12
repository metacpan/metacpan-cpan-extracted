#! perl

use strict;
use warnings;

use Test::More;

use Data::Transpose::Prefix;
use Data::Dumper;

my ($tp, $f, $output, $foo);

$tp = Data::Transpose::Prefix->new(prefix => 'duh_');
$f = $tp->field('foo');
isa_ok($f, 'Data::Transpose::Prefix::Field');

$output = $tp->transpose({foo => 6});

ok(exists $output->{duh_foo} && $output->{duh_foo} == 6,
   'simple transpose test foo with prefix duh_')
    || diag "Transpose output: " . Dumper($output);

$foo = Foo->new(foo => 6);

$output = $tp->transpose_object($foo);

ok(exists $output->{duh_foo} && $output->{duh_foo} == 6,
   'simple object transpose test with prefix duh_')
    || diag "Transpose output: " . Dumper($output);

$f->target('bar');
$output = $tp->transpose({foo => 6});

ok(exists $output->{duh_bar} && $output->{duh_bar} == 6,
   'simple transpose test foo => bar with prefix duh_')
    || diag "Transpose output: " . Dumper($output);

$foo = Foo->new(foo => 6);

$output = $tp->transpose_object($foo);

ok(exists $output->{duh_bar} && $output->{duh_bar} == 6,
   'simple object transpose test foo => bar with prefix duh_')
    || diag "Transpose output: " . Dumper($output);

done_testing;

package Foo;

use Moo;

has foo => (
    is => 'ro',
);

1;


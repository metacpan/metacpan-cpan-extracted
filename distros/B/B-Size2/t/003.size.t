use strict;
use warnings;
use Test::More;
use B ();
use B::Size2;

use Tie::Scalar;
use Tie::Array;
use Tie::Hash;

tie our $tied_scalar, 'Tie::StdScalar';
$tied_scalar= "foobar";

tie our %tied_hash, 'Tie::StdHash';
%tied_hash = (foo => 'bar');

tie our @tied_array, 'Tie::StdArray';
@tied_array = qw(foo bar);

my @values = (
    \undef,
    \10,
    \10.2,
    \"foo",
    [],
    [1],
    {},
    {foo => "bar"},
    Test::More->builder, # object
    \*STDOUT,
    sub { my($foo, $bar) },
    qr/foobar/,
    \$tied_scalar,
    \@tied_array,
    \%tied_hash,
);

plan tests => scalar @values;

for my $v(@values) {
    my $b = B::svref_2object($v);
    cmp_ok $b->size, ">", 0, ref($b) . " size: " . $b->size;
}


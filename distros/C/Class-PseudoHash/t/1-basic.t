#!/usr/bin/perl

use strict;
use Test::More tests => 9;

my ($class, $phash);

BEGIN {
    use_ok($class = 'Class::PseudoHash');
}

my @keys = qw/hello hay hoo aiph/;
my @arg = ([@keys], [ 1 .. 10 ]);
$phash = $class->new(@arg);

isa_ok($phash, $class, 'new()');

$phash = fields::phash(@arg);

isa_ok($phash, $class, 'phash()');

$phash->{hello} = 'hi';
$phash->{hay}   = 'hay';

is($phash->[1], 'hi', 'array access');
is($phash->{aiph}, 4, 'hash access');
eq_set([ keys(%$phash) ], \@keys, 'keys()');
is($#{$phash}, 4, 'fetchsize');
like("$phash", qr/^$class=ARRAY\(0x[0-9a-f]+\)$/, 'stringification');
is($phash ? 1 : 0, 1, 'bool context');
isnt(10 + $phash, 10, 'numeric context');

#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 12 }

use Class::MakeMethods::Template::Global
  'array' => [ qw / a b / ],
  'array' => 'c';

ok( 1 ); #1
ok( ! scalar @{X->a} ); #2
ok( X->push_a(123, 456) ); #3
ok( X->unshift_a('baz') ); #4
ok( X->pop_a == 456 ); #5
ok( X->shift_a eq 'baz' ); #6

ok( X->b(123, 'foo', qw / a b c /, 'bar') ); #7
ok do { #8
  my @l = X->b;
  $l[0] == 123 and
  $l[1] eq 'foo' and
  $l[2] eq 'a' and
  $l[3] eq 'b' and
  $l[4] eq 'c' and
  $l[5] eq 'bar'
};

ok do { #9
  X->splice_b(1, 2, 'baz');
  my @l = X->b;
  $l[0] == 123 and
  $l[1] eq 'baz' and
  $l[2] eq 'b' and
  $l[3] eq 'c' and
  $l[4] eq 'bar'
};

ok( ref X->b_ref eq 'ARRAY' ); #10
ok( ! scalar @{X->clear_b} ); #11
ok( ! scalar @{X->b} ); #12

exit 0;


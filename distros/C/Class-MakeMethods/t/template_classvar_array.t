#!/usr/bin/perl

package X;
use Class::MakeMethods::Template::ClassVar ( 
  'array' => [ qw / a b / ]
);

package Y;
@ISA = 'X';

package main;

use Test;
BEGIN { plan tests => 19 }

ok( 1 ); #1
ok( ! scalar @{X->a} ); #2
ok( X->push_a(123, 456) ); #3
ok( X->unshift_a('baz') ); #4
ok( ! scalar @{Y->a} ); #5
ok( X->pop_a == 456 ); #6
ok( X->shift_a eq 'baz' ); #7
ok( scalar @{X->a} == 1 ); #8
ok( Y->push_a(123, 456) ); #9
ok( scalar @{X->a} == 1 ); #10
ok( Y->unshift_a('baz') ); #11
ok( Y->pop_a == 456 ); #12
ok( Y->shift_a eq 'baz' ); #13

ok( X->b(123, 'foo', qw / a b c /, 'bar') ); #14
ok do { #15
  my @l = X->b;
  $l[0] == 123 and
  $l[1] eq 'foo' and
  $l[2] eq 'a' and
  $l[3] eq 'b' and
  $l[4] eq 'c' and
  $l[5] eq 'bar'
};

ok do { #16
  X->splice_b(1, 2, 'baz');
  my @l = X->b;
  $l[0] == 123 and
  $l[1] eq 'baz' and
  $l[2] eq 'b' and
  $l[3] eq 'c' and
  $l[4] eq 'bar'
};

ok( ref X->b_ref eq 'ARRAY' ); #17
ok( ! scalar @{X->clear_b} ); #18
ok( ! scalar @{X->b} ); #19

exit 0;


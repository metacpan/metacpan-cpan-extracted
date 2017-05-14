#!/usr/bin/perl

use Test;
BEGIN { plan tests => 12 }

package X;

use Class::MakeMethods::Template::Hash (
  new => 'new',
  array => [ qw / a b / ]
);

package main;

my $o = X->new;

ok( 1 ); #1
ok( ! scalar @{$o->a} ); #2
ok( $o->push_a(123, 456) ); #3
ok( $o->unshift_a('baz') ); #4
ok( $o->pop_a == 456 ); #5
ok( $o->shift_a eq 'baz' ); #6

ok( $o->b(123, 'foo', qw / a b c /, 'bar') ); #7
ok do {
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'foo' and
  $l[2] eq 'a' and
  $l[3] eq 'b' and
  $l[4] eq 'c' and
  $l[5] eq 'bar'
};

ok do {
  $o->splice_b(1, 2, 'baz');
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'baz' and
  $l[2] eq 'b' and
  $l[3] eq 'c' and
  $l[4] eq 'bar'
};

ok( ref $o->b_ref eq 'ARRAY' ); #8
ok( ! scalar @{$o->clear_b} ); #9
ok( ! scalar @{$o->b} ); #10

exit 0;


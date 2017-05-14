#!/usr/bin/perl

use Test;
BEGIN { plan tests => 15 }

package X;

use Class::MakeMethods::Template::Flyweight (
  new => 'new',
  array => [ qw / a b / ]
);

package main;

my $o = X->new;
my $o2 = X->new;

ok( 1 ); #1
ok( ! scalar @{$o->a} ); #2
ok( $o->push_a(123, 456) ); #3
ok( $o->unshift_a('baz') ); #4
ok( $o->pop_a == 456 ); #5
ok( $o->shift_a eq 'baz' ); #6
ok( ! scalar @{$o2->a} ); #7
ok( $o2->push_a(123, 456) ); #8

ok( $o->b(123, 'foo', qw / a b c /, 'bar') ); #9
ok do { #10
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'foo' and
  $l[2] eq 'a' and
  $l[3] eq 'b' and
  $l[4] eq 'c' and
  $l[5] eq 'bar'
};

ok do { #11
  $o->splice_b(1, 2, 'baz');
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'baz' and
  $l[2] eq 'b' and
  $l[3] eq 'c' and
  $l[4] eq 'bar'
};

ok( ref $o->b_ref eq 'ARRAY' ); #12
ok( ! scalar @{$o->clear_b} ); #13
ok( ! scalar @{$o->b} ); #14

ok do { #15
  my @l = $o2->a;
  $l[0] == 123 and
  $l[1] == 456
};

exit 0;


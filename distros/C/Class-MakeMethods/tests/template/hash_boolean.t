#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Hash (
  'bits' => [ qw / a b c d / ],
  'bits' => 'e'
);

sub new { bless {}, shift; }

package Y;

@ISA = 'X';

use Class::MakeMethods::Template::Hash (
  'bits' => [ qw / m n / ]
);

sub new { bless {}, shift; }

package main;

use Test;
BEGIN { plan tests => 19 }

my $o = new X;

ok( 1 ); #1

ok( ! $o->a ); #2
ok( ! $o->b ); #3
ok( ! $o->c ); #4
ok( ! $o->d ); #5
ok( ! $o->e ); #6

ok( $o->a(1) ); #7
ok( $o->a ); #8

ok( $o->set_a ); #9
ok( $o->a ); #10

ok( ! $o->a(0) ); #11
ok( ! $o->a ); #12

ok( ! $o->clear_a ); #13
ok( ! $o->a ); #14

my @f;
ok( @f = $o->bit_fields ); #15
ok do {
  $f[0] eq 'a' and
  $f[1] eq 'b' and
  $f[2] eq 'c' and
  $f[3] eq 'd' and
  $f[4] eq 'e'
};

ok do {
  $o->clear_a; $o->clear_b; $o->set_c;
  $o->set_d; $o->clear_e;
  my %f = $o->bit_hash;
  $f{'a'} == 0 and $f{'a'} == $o->a and
  $f{'b'} == 0 and $f{'b'} == $o->b and
  $f{'c'} == 1 and $f{'c'} == $o->c and
  $f{'d'} == 1 and $f{'d'} == $o->d and
  $f{'e'} == 0 and $f{'e'} == $o->e
};

my $y = new Y;
$y->set_a;
$y->clear_m;

ok do {
  $y->a;
};

ok do {
  ! $y->m;
};

exit 0;


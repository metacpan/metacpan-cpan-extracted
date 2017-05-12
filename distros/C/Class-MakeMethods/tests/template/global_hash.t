#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 17 }

use Class::MakeMethods::Template::Global (
  'hash' => [ qw / a b / ],
  'hash' => 'c'
);

sub new { bless {}, shift; }
my $o = new X;
my $o2 = new X;

ok( 1 ); #1
ok( ! scalar keys %{$o->a} ); #2
ok( ! defined $o->a('foo') ); #3
ok( $o->a_push('foo', 'baz') ); #4
ok( $o->a('foo') eq 'baz' ); #5
ok( $o->a_push('bar', 'baz2') ); #6
ok do { #7
  my @l = $o->a([qw / foo bar / ]);
  $l[0] eq 'baz' and $l[1] eq 'baz2'
};

ok( $o->a_push(qw / a b c d / ) ); #8
ok do { #9
  my %h = $o->a;
  my @l = sort keys %h;
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo'
};

ok do { #10
  my %h=('w' => 'x', 'y' => 'z');
  my $rh = \%h;
  my $r = $o->a_push($rh);
};

ok do { #11
  my @l = sort $o->a_keys;
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo' and
  $l[4] eq 'w' and
  $l[5] eq 'y'
};

ok do { #12
  my @l = sort $o->a_values;
  $l[0] eq 'b' and
  $l[1] eq 'baz' and
  $l[2] eq 'baz2' and
  $l[3] eq 'd' and
  $l[4] eq 'x' and
  $l[5] eq 'z'
};

ok( $o->b_tally(qw / a b c a b a d / ) ); #13
ok do { #14
  my %h = $o->b;
  $h{'a'} == 3 and
  $h{'b'} == 2 and
  $h{'c'} == 1 and
  $h{'d'} == 1
};

ok( ! defined $o->c('foo') ); #15
ok( defined $o->c ); #16

ok( $o->a eq $o2->a ); #17

exit 0;


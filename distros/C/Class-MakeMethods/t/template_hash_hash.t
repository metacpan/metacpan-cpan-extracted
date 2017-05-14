#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 24 }

use Class::MakeMethods::Template::Hash (
  'hash' => [ qw / a b / ],
  'hash' => 'c'
);

sub new { bless {}, shift; }
my $o = new X;

# 1--7
ok( 1 ); #1
ok( ! scalar keys %{$o->a} ); #2
ok( ! defined $o->a('foo') ); #3
ok( $o->a_push('foo', 'baz') ); #4
ok( $o->a('foo') eq 'baz' ); #5
ok( $o->a_push('bar', 'baz2') ); #6
ok do {
  my @l = $o->a([qw / foo bar / ]);
  $l[0] eq 'baz' and $l[1] eq 'baz2'
};

# 8--9
ok( $o->a_push(qw / a b c d / ) ); #7
ok do {
  my @l = sort keys %{$o->a};
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo'
};

# 10
ok do {
  my %h=('w' => 'x', 'y' => 'z');
  $o->a_push(\%h);
};

# 11
ok do {
  my @l = sort $o->a_keys;
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo'and
  $l[4] eq 'w' and
  $l[5] eq 'y'
};

#12
ok do {
  my @l = sort $o->a_values;
  $l[0] eq 'b' and
  $l[1] eq 'baz' and
  $l[2] eq 'baz2' and
  $l[3] eq 'd'and
  $l[4] eq 'x' and
  $l[5] eq 'z'
};

# 13--14
ok( $o->b_tally(qw / a b c a b a d / ) ); #8
ok do {
  my %h = $o->b;
  $h{'a'} == 3 and
  $h{'b'} == 2 and
  $h{'c'} == 1 and
  $h{'d'} == 1
};

# 15--19
ok( $o->c('foo', 'bar') ); #9
ok( $o->c('foo') eq 'bar' ); #10
ok( 1 ); #11
ok do { $o->c_delete('foo'); ! defined $o->c('foo') }; #12
ok( $o->c ); #13

#20
ok do {
  $o->c(qw / a b c d e f /);
  my %h = $o->c;
  $h{'a'} eq 'b' and
  $h{'c'} eq 'd' and
  $h{'e'} eq 'f'
};

#21
ok do {
  $o->c_delete(qw / a c /);
  my %h = $o->c;
  $h{'e'} eq 'f'
};

#22
ok do {
  my @l = sort keys %{$o->a};
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo' and
  $l[4] eq 'w' and
  $l[5] eq 'y'
};

#23
ok do {
  $o->a_clear;
  my @a_keys = $o->a_keys;
  @a == 0;
};

#24
ok do {
  $o->a ('a' => 1);
  my @l = keys %{$o->a};
  $l[0] eq 'a'
};

exit 0;


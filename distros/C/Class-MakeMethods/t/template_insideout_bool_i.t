#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 15 }

use Class::MakeMethods::Template::Flyweight (
  boolean_index => [ qw / a b / ],
  boolean_index => 'c'
);

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ); #1

ok( ! $o->a ); #2
ok( ! $o->b ); #3
ok( ! $o->c ); #4

ok( $o->a(1) ); #5
ok( $o->a ); #6

ok( $o->set_a ); #7
ok( $o->a ); #8

ok( ! $o->a(0) ); #9
ok( ! $o->a ); #10

ok( ! $o->clear_a ); #11
ok( ! $o->a ); #12

my $a = new X;
my $b = new X;
my $c = new X;
$a->set_a;
$b->set_a;
$c->set_a;


ok do { #13
  my %h = map { $_, $_ } X->find_a;
  my $f = 1;
  foreach (values %h) {
    $_->a or $f = 0;
  }
  $f;
};

ok do { #14
  my %h = map { $_, $_ } X->find_a;
  $h{$a} and $h{$b} and $h{$c};
};

ok do { #15
  $b->clear_a;
  my %h = map { $_, $_  } X->find_a;
  $h{$a} and !$h{$b} and $h{$c}
};


exit 0;


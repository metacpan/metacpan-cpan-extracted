#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Global (
  'scalar --with_clear' => [ qw / a b / ],
  'scalar --with_clear' => 'c'
);

sub new { bless {}, shift; }

package main;
use Test;
BEGIN { plan tests => 22 }

my $o = new X;
my $o2 = new X;

ok( 1 ); #1
ok( ! defined $o->a ); #2
ok( $o->a(123) ); #3
ok( $o->a == 123 ); #4
ok( $o2->a == 123 ); #5
ok( ! defined $o2->clear_a ); #6
ok( ! defined $o->a ); #7

ok( ! defined $o->b ); #8
ok( $o->b('hello world') ); #9
ok( $o->b eq 'hello world' ); #10
ok( $o2->b eq 'hello world' ); #11
ok( ! defined $o2->clear_b ); #12
ok( ! defined $o->b ); #13

my $foo = 'this';
ok( ! defined $o->c ); #14
ok( $o->c(\$foo) ); #15

$foo = 'that';

ok( $o->c eq \$foo ); #16
ok( $o2->c eq \$foo ); #17
ok( ${$o->c} eq ${$o2->c}); #18
ok( ${$o->c} eq 'that'); #19
ok( ${$o->c} eq 'that'); #20
ok( ! defined $o2->clear_c ); #21
ok( ! defined $o->c ); #22

exit 0;


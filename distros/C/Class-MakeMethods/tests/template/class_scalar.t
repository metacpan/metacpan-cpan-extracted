#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Class (
  'scalar' => [ qw / a b / ],
  'scalar' => { 'name' => 'c', 'variable' => 'Foozle' }
);

sub new { bless {}, shift; }

package Y;

@ISA = 'X';

package main;
use Test;
BEGIN { plan tests => 23 }

my $o = new X;
my $o2 = new Y;

ok( 1 ); #1

ok( ! defined $o->a ); #2
ok( $o->a(123) ); #3
ok( $o->a == 123 ); #4
ok( X->a == 123 ); #5
ok( ! $o2->a ); #6
ok( ! defined $o->a(undef) ); #7
ok( ! defined $o->a ); #8
ok( ! defined X->a ); #9

ok( ! defined $o->b ); #10
ok( X->b('nevermore') ); #11
ok( $o->b eq 'nevermore' ); #12
ok( X->b eq 'nevermore' ); #13
ok( ! defined $o2->b ); #14
ok( $o2->b('hello world') ); #15
ok( $o2->b eq 'hello world' ); #16
ok( Y->b eq 'hello world' ); #17
ok( ! defined $o->b(undef) ); #18
ok( ! defined X->b ); #19
ok( $o2->b eq 'hello world' ); #20

ok( ! defined X->c ); #21
ok( X->c(123) ); #22
ok( X->c == 123 ); #23

exit 0;


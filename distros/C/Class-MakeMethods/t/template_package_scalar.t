#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::PackageVar (
  'scalar' => [ qw / a b / ],
  'scalar' => { 'name' => 'c', 'variable' => 'Foozle' }
);

sub new { bless {}, shift; }

package Y;

@ISA = 'X';

package main;
use Test;
BEGIN { plan tests => 31 }

my $o = new X;
my $o2 = new Y;

ok( 1 ); #1
ok( ! defined $o->a ); #2
ok( $o->a(123) ); #3
ok( $o->a == 123 ); #4
ok( $o2->a == 123 ); #5
ok( ! defined $o2->a(undef) ); #6
ok( ! defined $o->a ); #7

ok( ! defined $o->b ); #8
ok( $o->b('hello world') ); #9
ok( $o->b eq 'hello world' ); #10
ok( $o2->b eq 'hello world' ); #11
ok( ! defined $o2->b(undef) ); #12
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
ok( ! defined $o2->c(undef) ); #21
ok( ! defined $o->c ); #22

ok( ! defined X->c ); #23
ok( X->c(123) ); #24
ok( X->c == 123 ); #25
ok( $X::Foozle = 123 ); #26
ok( ! defined $Y::Foozle ); #27
ok( $o2->c == 123 ); #28
ok( $X::Foozle = 1234 ); #29
ok( $o->c() == 1234 ); #30
ok( ! defined $Y::Foozle ); #31

exit 0;


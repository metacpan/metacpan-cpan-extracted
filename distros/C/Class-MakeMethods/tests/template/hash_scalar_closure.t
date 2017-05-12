#!/usr/bin/perl

use Test;
BEGIN { plan tests => 19 }

package X;

use Class::MakeMethods::Template::Hash (
  new      => 'new',
  'scalar --self_closure' => 'a b',
);

package main;

ok( 1 ); #1

my $o = X->new();
my $o2 = X->new();

my $oa = $o->a();
my $ob = $o->b();
my $o2a = $o2->a();

ok( ref( $oa and $ob and $o2a ) ); #2

ok( ! defined &$oa() ); #3
ok( &$oa(123) ); #4
ok( &$oa() == 123 ); #5

ok( ! defined &$o2a() ); #6
ok( &$o2a(911) ); #7
ok( &$o2a() == 911 ); #8
ok( ! defined &$o2a(undef) ); #9

ok( ! defined &$oa(undef) ); #10
ok( ! defined &$oa() ); #11
ok( &$oa(456) ); #12
ok( &$oa() == 456 ); #13

ok( ! defined &$ob() ); #14
ok( &$ob(911) ); #15
ok( &$ob() == 911 ); #16
ok( ! defined &$ob(undef) ); #17

ok( ! defined &$oa (undef) ); #18
ok( ! defined &$oa() ); #19

exit 0;


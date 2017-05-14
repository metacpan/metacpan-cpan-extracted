#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Static
  'number --counter' => [ qw / a b / ];

package main;
use Test;
BEGIN { plan tests => 8 }

ok( 1 ); #1
ok( X->a == 0 ); #2
ok( X->a == 0 ); #3
ok( X->a_incr == 1 ); #4
ok( X->a_incr == 2 ); #5
ok( X->a == 2 ); #6
ok( X->b == 0 ); #7
ok( X->b_incr == 1 ); #8

exit 0;


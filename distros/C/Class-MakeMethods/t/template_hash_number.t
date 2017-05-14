#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

package X;

use Class::MakeMethods::Template::Hash (
  new     => 'new',
  number  => [ qw/ a b c /]
);

package main;

my $o = X->new();

ok( 1 ); #1
ok( $o->a == 0 ); #2
ok( $o->a(123) ); #3
ok( $o->a == 123 ); #4
ok( $o->a(undef) == 0 ); #5
ok( $o->a == 0 ); #6
ok( $o->a("456") ); #7
ok( $o->a == 456 ); #8
ok( $o->a(undef) == 0 ); #9
ok( $o->a == 0 ); #10
ok( ! eval { $o->a("Foo"); 1 } ); #11

exit 0;


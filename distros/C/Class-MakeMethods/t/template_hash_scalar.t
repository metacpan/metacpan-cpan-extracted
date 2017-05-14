#!/usr/bin/perl

use Test;
BEGIN { plan tests => 10 }

package X;

use Class::MakeMethods::Template::Hash (
  new     => 'new',
  'scalar'  => [ qw/ a b c /]
);

package main;

my $o = X->new();

ok( 1 ); #1
ok( ! defined $o->a ); #2
ok( $o->a(123) ); #3
ok( $o->a == 123 ); #4
ok( ! defined $o->a(undef) ); #5
ok( ! defined $o->a ); #6
ok( $o->a(456) ); #7
ok( $o->a == 456 ); #8
ok( ! defined $o->a (undef) ); #9
ok( ! defined $o->a ); #10

exit 0;


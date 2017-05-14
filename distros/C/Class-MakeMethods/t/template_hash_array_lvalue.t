#!/usr/bin/perl

use Test;
BEGIN {
  eval q{ local $SIG{__DIE__}; require 5.6; 1 };
  if ( $@ ) {
    plan( tests => 1 );
    print "Skipping test on this platform (lvalue requires 5.6.0 or later).\n";
    ok( 1 );
    exit 0;
  }
}
BEGIN { plan tests => 9 }

package X;

use Class::MakeMethods::Template::Hash (
  new => 'new',
  'array --get --lvalue' => 'foo'
);

package main;

my $o = X->new;

ok( 1 ); #1
ok( ! scalar @{$o->foo} ); #2
ok( $o->foo = (123, 456) ); #3

ok( scalar( @a = $o->foo ) ); #4
ok( scalar(@a) == 2 and $o->foo->[1] == 456 ); #5

ok( ! scalar( @a = $o->foo() = () ) ); #6
ok( ! scalar @{$o->foo} ); #7
ok( $o->foo() = ('b', 'c', 'd') ); #8
ok( scalar( @a = $o->foo) == 3 and $o->foo->[1] eq 'c' ); #9

exit 0;


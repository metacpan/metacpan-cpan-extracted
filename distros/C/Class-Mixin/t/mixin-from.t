#!perl -T

use strict;
use Test::More tests => 7;

package foo;
sub s { return 'foo' };

package foo2;
use Class::Mixin from=> 'foo';
sub t { return 'blah' };

package main;

ok( foo->can('s'), 'foo can s' )
  && is( foo->s, 'foo', 'foo::s() matches' );
ok( ! foo->can('t'), "foo can't t" );

ok( foo2->can('s'), 'foo2 can s' )
  && is( foo2->s, 'foo', 'foo2::s() matches' );
ok( foo2->can('t'), 'foo can t' )
  && is( foo2->t, 'blah', 'foo2::t() matches' );


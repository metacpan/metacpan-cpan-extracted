#!perl

use strict;

use Test::More tests => 20;

package foo;
use Class::Mixin from => 'foo2';
sub s { return 'foo' };

package foo2;
sub t { return 'blah' };
sub u { return 'blah2' };

package main;

ok( foo->can('s'), 'foo can s' )
  && is( foo->s, 'foo', 'foo::s() matches' );
ok( foo->can('t'), 'foo can t' )
  && is( foo->t, 'blah', 'foo::t() matches' );
ok( foo->can('u'), 'foo can u' )
  && is( foo->u, 'blah2', 'foo::u() matches' );

ok( ! foo2->can('s'), "foo2 can't s" );
ok( foo2->can('t'), 'foo2 can t' )
  && is( foo2->t, 'blah', 'foo2::t() matches' );
ok( foo2->can('u'), 'foo2 can u' )
  && is( foo2->u, 'blah2', 'foo2::u() matches' );

# fake an unload (explicitly call DESTORY for coverage reasons)
Class::Mixin->__new->DESTROY;

ok( foo->can('s'), 'foo can s' )
  && is( foo->s, 'foo', 'foo::s() matches' );
ok( ! foo->can('t'), "foo can't t" );
ok( ! foo->can('u'), "foo can't u" );

ok( ! foo2->can('s'), "foo2 can't s" );
ok( foo2->can('t'), 'foo2 can t' )
  && is( foo2->t, 'blah', 'foo2::t() matches' );
ok( foo2->can('u'), 'foo2 can u' )
  && is( foo2->u, 'blah2', 'foo2::u() matches' );


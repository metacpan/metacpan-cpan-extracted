#!perl

use strict;
use warnings;
use Test::More tests => 7;

package foo;
sub s { return 'foo'; };
package foo2;
sub t { return 'blah'; };

require Class::Mixin;
import Class::Mixin to => 'foo';
Class::Mixin::resync();

package main;

ok( foo->can('s'), 'foo can s' )
  && is( foo->s, 'foo', 'foo::s() matches' );
ok( foo->can('t'), 'foo can t' )
  && is( foo->t, 'blah', 'foo::t() matches' );

ok( ! foo2->can('s'), "foo2 can't s" );
ok( foo2->can('t'), 'foo2 can t' )
  && is( foo2->t, 'blah', 'foo2::t() matches' );


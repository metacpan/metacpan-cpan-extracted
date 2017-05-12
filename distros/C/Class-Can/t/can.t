#!perl -w
use strict;
use Test::More tests => 3;
use Class::Can;

package Foo;
sub foo {}

package Bar;
use base qw( Foo );
sub bar {}

package Baz;
use base qw( Bar );
sub foo {}
sub baz {}

package main;

is_deeply( { Class::Can->interrogate( 'Foo' ) },
           {
               foo => 'Foo',
           }, "understands Foo");

is_deeply( { Class::Can->interrogate( 'Bar' ) },
           {
               foo => 'Foo',
               bar => 'Bar',
           }, "understands Bar");

is_deeply( { Class::Can->interrogate( 'Baz' ) },
           {
               foo => 'Baz',
               bar => 'Bar',
               baz => 'Baz',
           }, "understands Baz");

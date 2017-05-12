#!/usr/bin/perl

##
## Tests for accessors::chained
##

#use blib;
use strict;
use warnings;

BEGIN {
  eval q{ local $SIG{__DIE__}; require Test::More; 1 };
  if ( $@ ) {
    plan( tests => 1 );
    print "Skipping test on this platform (test requires Test::More).\n";
    ok( 1 );
    exit 0;
  }
}

use Test::More tests => 6;
use Carp;

BEGIN { use_ok("Class::MakeMethods::Emulator::accessors") };
use Class::MakeMethods::Emulator::accessors::chained ('-take_namespace');

# BEGIN { Class::MakeMethods::Emulator::accessors::chained->import('-take_namespace') };

my $time = shift || 1;

my $foo = bless {}, 'Foo';
can_ok( $foo, 'bar' );
can_ok( $foo, 'baz' );

is( $foo->bar( 'set' )->baz( 2 ), $foo, 'set foo->bar->baz' );
is( $foo->bar, 'set',   'get foo->bar' );
is( $foo->baz, '2',     'get foo->baz' );

package Foo;
use accessors::chained qw( bar baz );

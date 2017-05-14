#!/usr/bin/perl

##
## Tests for invalid accessors
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
BEGIN { import Class::MakeMethods::Emulator::accessors '-take_namespace' };

## use default style:
my $foo = bless {}, 'Foo';
can_ok( $foo, 'bar' );
can_ok( $foo, 'baz' );

ok( $foo->bar( 1 ), 'set default' );
is( $foo->bar, 1 ,  'get default' );
ok( !$foo->baz,     'get default');

package Foo;
use accessors qw( bar baz );

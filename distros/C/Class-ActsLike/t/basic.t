#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use Test::More tests => 10;

my $package = 'Class::ActsLike';
use_ok( $package ) or exit;

can_ok( $package, 'import' );
can_ok( UNIVERSAL => 'acts_like' );

package Foo;

$package->import(qw( Bar quux ));

package Bar;
use vars qw( @ISA );
@ISA = 'Foo';

package Baz;
use vars qw( @ISA );
@ISA = 'Bar';

package foo;

use vars qw( @ISA );

package Quux;
use vars qw( @ISA );
@ISA = ('foo', 'Baz');

package main;

my $foo = bless {}, 'Foo';

ok( $foo->acts_like( 'Foo' ), 'class should act like itself' );
ok( $foo->acts_like( 'Bar' ), '... and any other classes declared on import' );
ok( ! $foo->acts_like( 'Baz' ), '... but no other classes' );

my $bar = bless {}, 'Bar';

ok( $bar->acts_like( 'Foo' ), '... subclass should act like parent class' );
ok( $bar->acts_like( 'quux' ), '... and classes the parent acts like' );

my $baz = bless {}, 'Baz';
ok( $baz->acts_like( 'Foo' ), '... or a grandparent acts like' );

my $quux = bless {}, 'Quux';
ok( $quux->acts_like( 'quux' ), '... even if not a leftmost ancestor' );

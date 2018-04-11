#!/usr/bin/perl

# Main testing for Class::Adapter::Clear

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Scalar::Util 'refaddr';
use Class::Adapter::Clear ();

# Create a Foo object and it's clear wrapper
my $Foo = Foo->new;
isa_ok( $Foo, 'Foo' );
my $clear = Class::Adapter::Clear->new( $Foo );
is( ref($clear), 'Class::Adapter::Clear', 'Object is the right ref type' );
isa_ok( $clear, 'Foo' );
my $Bar = Bar->new( $Foo );
is( ref($Bar), 'Bar', 'Object is the right ref type' );
isa_ok( $Bar, 'Foo' );

# Check various calls
is( $Foo->foo, 'foo', 'Foo->foo is correct' );
is( $Foo->bar, 'bar', 'Foo->bar is correct' );
is( $clear->foo, 'foo', 'Clear->foo is correct' );
is( $clear->bar, 'bar', 'Clear->bar is correct' );
is( $Bar->foo, 'bar', 'Bar->foo is correct' );
is( $Bar->bar, 'bar', 'Bar->bar is correct' );





package Foo;

sub new {
	bless {}, shift;
}

sub foo { 'foo' }

sub bar { 'bar' }

1;

package Bar;

use base 'Class::Adapter::Clear';

sub foo { shift->_OBJECT_->bar }

1;

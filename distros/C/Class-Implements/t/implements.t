#!perl
use strict;
use warnings;
use Test::More tests => 3;
my $class = 'Class::Implements';
require_ok( $class );

package Foo;
$class->import( 'Bar' );

package main;
my $liar = bless {}, "Foo";
isa_ok( $liar, "Foo" );

# and this one lies
isa_ok( $liar, "Bar" );

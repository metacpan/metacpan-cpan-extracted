#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use Curio::Factory;

my $class = 'CC';
package CC;
    use Moo;
    with 'Curio::Role';
package main;

is( $class->factory(), undef, 'factory() returned undef' );

Curio::Factory->new( class=>$class );

isa_ok( $class->factory(), ['Curio::Factory'], 'factory() returned a factory' );

done_testing;

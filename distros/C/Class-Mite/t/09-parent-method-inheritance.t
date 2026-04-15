#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Parent class
{
    package ParentFoo;
    use Class;

    sub greet { return "Hello from ParentFoo" }
}

# Child class
{
    package ChildFoo;
    use Class;
    extends 'ParentFoo';
}

# Create child object
my $child = ChildFoo->new;

ok($child, 'Child object created');
isa_ok($child, 'ChildFoo', 'Object is a ChildFoo');
isa_ok($child, 'ParentFoo', 'Object also inherits ParentFoo');

# Test inherited method
is($child->greet, 'Hello from ParentFoo', 'Inherited method accessible from child');

done_testing;

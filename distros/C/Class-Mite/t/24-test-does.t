#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Class;
use Role;

# Define a simple role
{
    package TestRole;
    use Role;

    sub role_method { "from role" }
}

# Define a class that uses the role
{
    package TestClassWithRole;
    use Class;
    with 'TestRole';

    sub class_method { "from class" }
}

# Define a class without the role
{
    package TestClassWithoutRole;
    use Class;

    sub class_method { "from class" }
}

# Define a subclass
{
    package TestSubClass;
    use Class;
    extends 'TestClassWithoutRole';
}

package main;

# Test 1: Object with role DOES the role
my $with_role = TestClassWithRole->new;
ok($with_role->DOES('TestRole'), 'Object with role DOES the role');
ok($with_role->does('TestRole'), 'Object with role does() the role');

# Test 2: Object without role does NOT DO the role
my $without_role = TestClassWithoutRole->new;
ok(!$without_role->DOES('TestRole'), 'Object without role does NOT DO the role');
ok(!$without_role->does('TestRole'), 'Object without role does not do() the role');

# Test 3: Inheritance check with DOES
my $subclass = TestSubClass->new;
ok($subclass->DOES('TestClassWithoutRole'), 'Subclass DOES parent class');
ok($subclass->isa('TestClassWithoutRole'), 'Subclass isa parent class (backwards compatible)');

# Test 4: Self check
ok($with_role->DOES('TestClassWithRole'), 'Object DOES its own class');
ok($without_role->DOES('TestClassWithoutRole'), 'Object DOES its own class');

# Test 5: Non-existent role/class
ok(!$with_role->DOES('NonExistentRole'), 'Returns false for non-existent role');
ok(!$without_role->DOES('NonExistentClass'), 'Returns false for non-existent class');

done_testing;

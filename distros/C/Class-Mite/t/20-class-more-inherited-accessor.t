#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Simple parent class with attributes
{
    package Animal;
    use Class::More;
    has name => (required => 1);
    has age  => (default => 0);
}

# Child class that inherits from Animal
{
    package Dog;
    use Class::More;
    extends 'Animal';
    has breed => (default => 'Mixed');
}

# Test 1: Child class can access parent attributes via methods
my $dog = Dog->new(name => 'Rex');
is($dog->name, 'Rex', "Inherited name accessor works");
is($dog->age, 0, "Inherited age accessor with default works");
is($dog->breed, 'Mixed', "Child's own accessor works");

# Test 2: Setters work for inherited attributes
$dog->name('Spot');
$dog->age(3);
is($dog->name, 'Spot', "Inherited name setter works");
is($dog->age, 3, "Inherited age setter works");

# Test 3: Required attribute from parent is enforced
eval {
    my $bad_dog = Dog->new();  # Missing required 'name'
};
like($@, qr/Required attribute 'name' not provided/,
     "Required attribute from parent is enforced");

# Test 4: Multiple inheritance levels
{
    package Puppy;
    use Class::More;
    extends 'Dog';
    has size => (default => 'small');
}

my $puppy = Puppy->new(name => 'Tiny');
is($puppy->name, 'Tiny', "Grandparent accessor works");
is($puppy->size, 'small', "Own accessor works in grandchild");

done_testing;

#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

{
    package Test::Person;
    use Class::More;

    has name => (required => 1);
    has age  => (default => 18);
    has city => (default => 'Unknown');
}

# Test basic construction
my $person = Test::Person->new(name => 'John');
isa_ok($person, 'Test::Person', 'Object created');
is($person->name, 'John', 'Required attribute set');
is($person->age, 18, 'Default attribute set');
is($person->city, 'Unknown', 'Default string attribute set');

# Test attribute modification
$person->age(25);
is($person->age, 25, 'Attribute can be modified');

# Test required attribute
eval { Test::Person->new() };
like($@, qr/Required attribute 'name' not provided/, 'Required attribute enforced');

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Test class with various attribute combinations
{
    package Test::Person;
    use Class::More;

    has name    => (required => 1);
    has age     => (default => 25);
    has title   => (required => 1, default => sub { 'Developer' });
    has active  => (default => 1);
}

# Test 1: Required attribute without default - should die
eval {
    my $person = Test::Person->new();
};
like($@, qr/Required attribute 'name' not provided/,
     "Dies when required attribute 'name' is missing");

# Test 2: Required attribute provided - should work
eval {
    my $person = Test::Person->new(name => 'Alice', title => 'Manager');
    is($person->{name}, 'Alice', "Required attribute 'name' is set correctly");
    is($person->{title}, 'Manager', "Required attribute 'title' is set correctly");
};
is($@, '', "No error when required attributes are provided");

# Test 3: Default values applied for non-required attributes
eval {
    my $person = Test::Person->new(name => 'Bob', title => 'Tester');
    is($person->{age}, 25, "Default value for 'age' is applied");
    is($person->{active}, 1, "Default value for 'active' is applied");
};
is($@, '', "No error when checking default values");

# Test 4: Required attribute with code default - should work without explicit value
eval {
    my $person = Test::Person->new(name => 'Charlie');
    is($person->{title}, 'Developer', "Code reference default for 'title' is applied");
};
is($@, '', "No error when using code reference default for required attribute");

done_testing;

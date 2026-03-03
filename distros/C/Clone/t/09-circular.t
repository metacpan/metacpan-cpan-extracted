#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use Clone qw(clone);

# Test 1: Simple circular reference in array
{
    my $array = [];
    $array->[0] = $array;  # Create circular reference
    my $clone = eval { clone($array) };
    ok(!$@, "Cloning circular array reference should not die")
        or diag("Error: $@");
    ok(ref($clone) eq 'ARRAY', "Clone is an array reference");
    is("$clone", "$clone->[0]", "Circular reference should be maintained in clone");
}

# Test 2: Circular reference in hash
{
    my $hash = {};
    $hash->{self} = $hash;  # Create circular reference
    my $clone = eval { clone($hash) };
    ok(!$@, "Cloning circular hash reference should not die")
        or diag("Error: $@");
    ok(ref($clone) eq 'HASH', "Clone is a hash reference");
    is("$clone", "$clone->{self}", "Circular hash reference should be maintained in clone");
}

# Test 3: Verify clone is independent from original
{
    my $array = [];
    $array->[0] = $array;
    $array->[1] = 'original';
    my $clone = eval { clone($array) };
    $clone->[1] = 'cloned';
    is($array->[1], 'original', "Modifying clone does not affect original");
}

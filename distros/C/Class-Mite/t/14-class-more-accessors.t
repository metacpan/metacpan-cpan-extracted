#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

{
    package Test::Accessors;
    use Class::More;

    has name => ();
    has count => (default => 0);
    has list => (default => sub { [] });
}

my $obj = Test::Accessors->new(name => 'Test');

# Test getter
is($obj->name, 'Test', 'Getter works for provided value');
is($obj->count, 0, 'Getter works for default value');

# Test setter
$obj->name('Modified');
is($obj->name, 'Modified', 'Setter works for string');

$obj->count(42);
is($obj->count, 42, 'Setter works for number');

# Test complex data structures
my $array_ref = $obj->list;
is(ref $array_ref, 'ARRAY', 'Default coderef returns arrayref');
is(scalar @$array_ref, 0, 'Arrayref is empty');

push @$array_ref, 'item';
is($obj->list->[0], 'item', 'Can modify returned reference');

# But setting should replace the reference
$obj->list(['new', 'array']);
is_deeply($obj->list, ['new', 'array'], 'Setter replaces reference');

done_testing;

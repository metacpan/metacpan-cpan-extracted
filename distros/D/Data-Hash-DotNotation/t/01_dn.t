#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use Data::Hash::DotNotation;
use Test::More;
use Test::Exception;

my $testObject = Data::Hash::DotNotation->new();

# "data" attribute of object should point to a hash
is(ref $testObject->data(), 'HASH', '"data" points to a hash when instantiated');

# hash should be empty
my $size = keys %{$testObject->data};
is($size, 0, '"data" ought to be empty');
throws_ok { $testObject->set() } qr/No name given/, 'A name or "key" must be provided to the "set" method';

is($testObject->set("fname"), undef, 'Adding a key without a value returns a null value');
$size = keys %{$testObject->data};
is($size, 0, '"data" should still be empty here');

is($testObject->set("lname", "Wall"), 'Wall', 'Adding a key value pair returns the value');
$size = keys %{$testObject->data};
is($size, 1, '"data" should contain only one elements');

is($testObject->set("fname", "Larry"), 'Larry', 'Adding another key value pair returns the value');
$size = keys %{$testObject->data};
is($size, 2, '"data" should now contain two elements');

is($testObject->key_exists("mname"), '', 'Searching for a non-existent key returns an empty string');
is($testObject->key_exists("fname"), 1,  'But searching for an existing key should return true');

throws_ok { $testObject->get() } qr/No name given/, 'A name or "key" must be provided to the "get" method';
is($testObject->get("mname"), undef,   'If the key does not exist, a null object is returned');
is($testObject->get("fname"), 'Larry', 'The value for the key is returned if it exists');

is($testObject->set("field1.field2.field3", "fieldValue"), 'fieldValue', "There\'s also this strange key \(field1.field2.field3\) that can be used");
is($testObject->get("field1.field2.field3"), 'fieldValue', 'This strange key returns the expected value passed it');
$size = keys %{$testObject->data};
is($size, 3, '"data" should now contain three elements');

done_testing();

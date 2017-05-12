#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;

package MyClass;
use Moose;
with 'Data::Serializable';
no Moose;

package main;
my $obj = MyClass->new();

# Private methods
ok($obj->can('_wrap_invalid'), '_wrap_invalid is private');
ok($obj->can('_unwrap_invalid'), '_unwrap_invalid is private');
ok($obj->can('_build_serializer'), '_build_serializer is private');
ok($obj->can('_build_deserializer'), '_build_deserializer is private');

# Public methods
ok($obj->can('serializer_module'), 'serializer_module is visible');
ok($obj->can('serializer'), 'serializer is visible');
ok($obj->can('deserializer'), 'deserializer is visible');
ok($obj->can('serialize'), 'serialize is visible');
ok($obj->can('deserialize'), 'deserialize is visible');

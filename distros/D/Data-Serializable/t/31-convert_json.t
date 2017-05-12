#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Module::Runtime ();
eval { Module::Runtime::require_module("Data::Serializer") };
plan( skip_all => "Please install Data::Serializer" )
    if $@;

plan( tests => 6 );

package MyClass;
use Moose;
with 'Data::Serializable';
#has '+throws_exception' => ( default => 0 );
no Moose;

package main;
my $obj = MyClass->new( serializer_module => 'JSON' );
my $str = "Test";
my $array = [ qw( a b c ) ];
my $hash = { a => "b", c => "d" };
my $str_conv = $obj->deserialize($obj->serialize($str));
my $array_conv = $obj->deserialize($obj->serialize($array));
my $hash_conv = $obj->deserialize($obj->serialize($hash));
is( $str_conv, $str, 'string serialization/deserialization works' );
is_deeply( $array_conv, $array, 'arrayref serialization/deserialization works' );
is_deeply( $hash_conv, $hash, 'hashref serialization/deserialization works' );

# Handle conversion of undef via JSON
my $nothing = undef;
my $nothing_serialized = '{"_serialized_object":null}';
my $nothing_packed = $obj->serialize($nothing);
is( $nothing_packed, $nothing_serialized, 'undef serialization works');
my $nothing_unpacked = $obj->deserialize($nothing_packed);
is( $nothing_unpacked, $nothing, 'undef deserialization works');

# Make sure deserializing undef returns undef
lives_ok { $obj->deserialize(undef) } "deserializing undef doesn't die";

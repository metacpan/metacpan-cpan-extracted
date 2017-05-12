#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

package MyClass;
use Moose;
with 'Data::Serializable';
#has '+throws_exception' => ( default => 0 );
no Moose;

package main;
my $obj = MyClass->new();
my $str = "Test";
my $array = [ qw( a b c ) ];
my $hash = { a => "b", c => "d" };
my $str_conv = $obj->deserialize($obj->serialize($str));
my $array_conv = $obj->deserialize($obj->serialize($array));
my $hash_conv = $obj->deserialize($obj->serialize($hash));
is( $str_conv, $str, 'string serialization/deserialization works' );
is_deeply( $array_conv, $array, 'arrayref serialization/deserialization works' );
is_deeply( $hash_conv, $hash, 'hashref serialization/deserialization works' );

# Handle conversion of undef via Storable
my $nothing = undef;
my $nothing_conv = $obj->deserialize($obj->serialize($nothing));
is( $nothing_conv, $nothing, 'undef serialization/deserialization works');

# Make sure deserializing undef returns undef
lives_ok { $obj->deserialize(undef) } "deserializing undef doesn't die";

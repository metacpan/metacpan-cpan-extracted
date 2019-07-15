use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;

use BSON qw/encode decode/;
use BSON::Types ':all';
use boolean;

my ( $bson, $expect, $hash );

# test constructor
isa_ok( bson_bool(),  'boolean', "bson_bool() gives boolean.pm" );
isa_ok( bson_bool(0), 'boolean', "bson_bool(0) gives boolean.pm" );
isa_ok( bson_bool(1), 'boolean', "bson_bool(1) gives boolean.pm" );

# test overloading
ok( !bson_bool(),  "bson_bool() is false" );
ok( !bson_bool(0), "bson_bool(0) is false" );
ok( bson_bool(1),  "bson_bool(1) is true" );

# boolean -> boolean
$bson = $expect = encode( { A => true } );
$hash = decode($bson);
is( ref( $hash->{A} ), 'boolean', "boolean->boolean" );
ok( $hash->{A}, "value is correct" );

# mock various classes we support
my @mocks = qw(
  BSON::Bool
  JSON::XS::Boolean
  JSON::PP::Boolean
  JSON::Tiny::_Bool
  Mojo::JSON::_Bool
  Cpanel::JSON::XS::Boolean
  Types::Serialiser::Boolean
);

for my $c ( @mocks ) {
    my $bool = bless \(my $b = 1), $c;
    $bson = encode( { A => $bool } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'boolean', "$c->boolean" );
    ok( $hash->{A}, "value is correct" );
    is($bson, $expect, "BSON is correct" );
}

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:

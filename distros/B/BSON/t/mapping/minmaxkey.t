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

my ( $bson, $expect, $hash );

# test constructor
isa_ok( bson_maxkey(), "BSON::MaxKey", "bson_maxkey" );
isa_ok( bson_minkey(), "BSON::MinKey", "bson_minkey" );

isa_ok( BSON::MaxKey->new(), "BSON::MaxKey", "bson_maxkey" );
isa_ok( BSON::MinKey->new(), "BSON::MinKey", "bson_minkey" );

# BSON::MaxKey -> BSON::MaxKey
$bson = $expect = encode( bson_doc( A => bson_maxkey(), B => bson_minkey() ) );
$hash = decode($bson);
is( ref( $hash->{A} ), 'BSON::MaxKey', "BSON::MaxKey->BSON::MaxKey" );
is( ref( $hash->{B} ), 'BSON::MinKey', "BSON::MinKey->BSON::MinKey" );

# MongoDB::[Min|Max]Key (deprecated) -> BSON::Regex
$bson = encode( bson_doc( A => bless( {}, 'MongoDB::MaxKey' ), B => bless( {}, 'MongoDB::MinKey' ) ) );
$hash = decode( $bson  );
is( ref( $hash->{A} ), 'BSON::MaxKey', "BSON::MaxKey->BSON::MaxKey" );
is( ref( $hash->{B} ), 'BSON::MinKey', "BSON::MinKey->BSON::MinKey" );
is( $bson, $expect, "BSON correct" );

eval { to_myjson({a=>bson_maxkey()}) };
like( $@, qr/illegal in JSON/, 'json throws: bson_maxkey()' );
eval { to_myjson({a=>bson_minkey()}) };
like( $@, qr/illegal in JSON/, 'json throws: bson_minkey()' );

# to extended JSON
is( to_extjson({a=>bson_minkey()}), q[{"a":{"$minKey":1}}], 'extjson: bson_minkey' );
is( to_extjson({a=>bson_maxkey()}), q[{"a":{"$maxKey":1}}], 'extjson: bson_maxkey' );

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

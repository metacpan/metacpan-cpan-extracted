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
use Tie::IxHash;

my ( $bson, $expect, $hash );

# test BSON::DBRef constructor
eval { bson_dbref() };
like( $@, qr/arguments to bson_dbref/i, "empty bson_dbref() throws error" );

eval { bson_dbref("12345") };
like( $@, qr/arguments to bson_dbref/i, "bson_dbref(ID) throws error" );

eval { bson_dbref( "12345", "test", more => "stuff" ) };
like( $@, qr/arguments to bson_dbref/i, "bson_dbref(ID,REF,EXTRA) throws error" );

# test mapping

my $dbref = bson_dbref( "12345", "foo" );
my $input = { A => $dbref };

# BSON::DBRef-> BSON::DBRef
{
    $expect = $bson = encode($input);
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::DBRef', "BSON::DBRef->BSON::DBRef" );
    is( $hash->{A}->id,    $dbref->id,    "DBRef id" );
    is( $hash->{A}->ref,   $dbref->ref,   "DBRef ref" );
}

# BSON::DBRef->HASH
{
    $expect = $bson = encode($input);
    $hash = decode( $bson, wrap_dbrefs => 0 );
    is( ref( $hash->{A} ),  'HASH',      "BSON::DBRef->HASH" );
    is( $hash->{A}{'$id'},  $dbref->id,  "\$id" );
    is( $hash->{A}{'$ref'}, $dbref->ref, "\$ref" );
}

# MongoDB::DBRef -> BSON::Regex
SKIP: {
    $ENV{PERL_MONGO_NO_DEP_WARNINGS} = 1;
    eval { require MongoDB::DBRef };
    skip( "MongoDB::DBRef v1.0.0+ not installed", 4 )
      unless $INC{'MongoDB/DBRef.pm'} && eval {MongoDB::DBRef->VERSION("v1.0.0")};
    $bson =
      encode( { A => MongoDB::DBRef->new( id => $dbref->id, 'ref' => $dbref->ref ) } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::DBRef', "MongoDB::DBRef->BSON::DBRef" );
    is( $hash->{A}->id,    $dbref->id,    "DBRef id" );
    is( $hash->{A}->ref,   $dbref->ref,   "DBRef ref" );
    is( $bson,             $expect,       "BSON correct" );
}

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:

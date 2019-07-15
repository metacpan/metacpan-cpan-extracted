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

use MIME::Base64;
use BSON qw/encode decode/;
use BSON::Types ':all';

my ($bson, $expect, $hash);

my $bindata = "\1\2\3\4\5";

# test constructor
is( bson_bytes(), '', "empty bson_bytes() is ''" );
is( BSON::Bytes->new->data, '', "empty BSON::Bytes constructor is ''" );
is( bson_bytes($bindata, 2)->subtype, 2, "bson_bytes(\$data, \$subtype) works" );

# test overloading
is( bson_bytes($bindata), $bindata, "BSON::Bytes string overload" );

# BSON::Bytes -> BSON::Bytes
$bson = $expect = encode( { A => bson_bytes($bindata) } );
$hash = decode( $bson );
is( ref( $hash->{A} ), 'BSON::Bytes', "BSON::Bytes->BSON::Bytes" );
is( "$hash->{A}", $bindata, "value correct" );

# scalarref -> BSON::Bytes
$bson = encode( { A => \$bindata } );
$hash = decode( $bson );
is( ref( $hash->{A} ), 'BSON::Bytes', "scalarref->BSON::Bytes" );
is( "$hash->{A}", $bindata, "value correct" );
is( $bson, $expect, "BSON correct" );

# BSON::Binary (deprecated) -> BSON::Bytes
$hash = encode( { A => BSON::Binary->new($bindata) } );
$hash = decode( $bson  );
is( ref( $hash->{A} ), 'BSON::Bytes', "BSON::Binary->BSON::Bytes" );
is( "$hash->{A}", $bindata, "value correct" );
is( $bson, $expect, "BSON correct" );

# MongoDB::BSON::Binary (deprecated) -> BSON::Bytes
SKIP: {
    $ENV{PERL_MONGO_NO_DEP_WARNINGS} = 1;
    eval { require MongoDB::BSON::Binary };
    skip( "MongoDB::BSON::Binary not installed", 2 )
      unless $INC{'MongoDB/BSON/Binary.pm'};
    $bson = encode( { A => MongoDB::BSON::Binary->new( data => $bindata ) } );
    $hash = decode( $bson  );
    is( ref( $hash->{A} ), 'BSON::Bytes', "MongoDB::BSON::Binary->BSON::Bytes" );
    is( "$hash->{A}",      $bindata,      "value correct" );
    is( $bson, $expect, "BSON correct" );
}

# to JSON
my $test_data = "\1\2\3\4\0\1\2\3\4";
my $b64_data = encode_base64($test_data, "");
is( to_myjson({a=>bson_bytes($test_data)}), qq[{"a":"$b64_data"}], 'json: bson_bytes(<data>)' );

# to extended JSON
is( to_extjson({a=>bson_bytes($test_data)}), qq[{"a":{"\$binary":{"base64":"$b64_data","subType":"00"}}}], 'extjson: bson_bytes(<data>)' );
is( to_extjson({a=>bson_bytes($test_data,128)}), qq[{"a":{"\$binary":{"base64":"$b64_data","subType":"80"}}}], 'extjson: bson_bytes(<data>,128)' );

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

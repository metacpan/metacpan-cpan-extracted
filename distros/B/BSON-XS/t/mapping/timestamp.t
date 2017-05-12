use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use CleanEnv;
use TestUtils;

use BSON qw/encode decode/;
use BSON::Types ':all';

my ($bson, $expect, $hash);

my $seconds = time;
my $increment = 42;

# test constructor
ok( bson_timestamp()->seconds >= $seconds, "bson_timestamp()->seconds" );
is( bson_timestamp()->increment, 0, "bson_timestamp()->increment" );
is( bson_timestamp($seconds)->seconds, $seconds, "bson_timestamp(seconds)->seconds" );
is( bson_timestamp($seconds)->increment, 0, "bson_timestamp(seconds)->increment" );
is( bson_timestamp( $seconds, $increment )->seconds, $seconds, "bson_timestamp(seconds, increment)->seconds" );
is( bson_timestamp( $seconds, $increment )->increment, $increment, "bson_timestamp(seconds, increment)->increment" );

ok( BSON::Timestamp->new()->seconds >= $seconds, "BSON::Timestamp->new()->seconds" );
is( BSON::Timestamp->new()->increment,   0, "BSON::Timestamp->new()->increment" );
is( BSON::Timestamp->new( seconds => $seconds )->seconds, $seconds, "BSON::Timestamp->new(seconds)->seconds" );
is( BSON::Timestamp->new( seconds => $seconds )->increment, 0, "BSON::Timestamp->new(seconds)->increment" );
is( BSON::Timestamp->new( seconds => $seconds, increment => $increment )->seconds, $seconds, "BSON::Timestamp->new(seconds, increment)->seconds" );
is( BSON::Timestamp->new( seconds => $seconds, increment => $increment )->increment  , $increment, "BSON::Timestamp->new(seconds, increment)->increment" );

# BSON::Timestamp -> BSON::Timestamp
$bson = $expect = encode( { A => bson_timestamp($seconds, $increment) } );
$hash = decode( $bson );
is( ref( $hash->{A} ), 'BSON::Timestamp', "BSON::Timestamp->BSON::Timestamp" );
is( $hash->{A}->seconds, $seconds, "seconds correct" );
is( $hash->{A}->increment, $increment, "increment correct" );

# MongoDB::Timestamp (deprecated) -> BSON::Timestamp
SKIP: {
    eval { require MongoDB::Timestamp };
    skip( "MongoDB::Timestamp not installed", 2 )
      unless $INC{'MongoDB/Timestamp.pm'};
    $bson = encode( { A => MongoDB::Timestamp->new( sec => $seconds, inc => $increment ) } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'BSON::Timestamp', "MongoDB::Timestamp->BSON::Timestamp" );
    is( $hash->{A}->seconds, $seconds, "seconds correct" );
    is( $hash->{A}->increment, $increment, "increment correct" );
    is( $bson, $expect, "BSON correct" );
}

# to JSON
eval { to_myjson({a=>bson_timestamp()}) };
like( $@, qr/illegal in JSON/, 'json throws: bson_timestamp()' );

# to extended JSON
is(
    to_extjson( { a => bson_timestamp( $seconds, $increment ) } ),
    qq[{"a":{"\$timestamp":{"i":$increment,"t":$seconds}}}],
    'extjson: bson_timestamp(<secs>,<inc>)'
);


done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2016 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:

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

{
    my $obj = bless {}, "Some::Random::Class";
    eval { encode( { a => $obj } ) };
    like( $@, qr/For key 'a', can't encode value of type 'Some::Random::Class'/, "encoding unknown type is fatal" );
}

{
    my $bson = encode( { a => 1.1 } );
    # swap the type byte to an unknown one
    substr($bson,4,1,"\xEE");
    eval { decode($bson) };
    like(
        $@,
        qr/unsupported BSON type \\xEE for key 'a'\.  Are you using the latest version/,
        "decoding unknown type is fatal"
    );
}

{
    no warnings 'once';
    my $glob = *foo;
    eval { encode( \$glob ) };
    like( $@, qr/Can't encode non-container of type 'GLOB'/, "encoding non-container is fatal" );
}

{
    my $with_null= "Hello\0World";
    eval { encode( { $with_null => 123 } ) };
    like( $@, qr/Key 'Hello\\x00World' contains null character/, "encoding embedded null is fatal" );
}

{
    eval { encode( "Hello world" ) };
    like( $@, qr/Can't encode scalars/, "encoding scalar is fatal" );
}


{
    eval { encode( qr/abc/ ) };
    like( $@, qr/Can't encode non-container of type '.*'/, "encoding non-container is fatal" );
}

{
    my $str = "123";
    my $obj = bless \$str, "Some::Object";
    eval { encode( $obj ) };
    like( $@, qr/Can't encode non-container of type 'Some::Object'/, "encoding hash-type object is fatal" );
}

subtest nesting => sub {
    my $err;

    eval { encode( create_nest(100) ) };
    $err = $@;
    is( $err, '', "No error encoding 100 levels of hash" );

    eval { encode( create_nest(101) ) };
    $err = $@;
    like(
        $err,
        qr/Exceeded max object depth of 100/,
        "Hit the specified max depth encoding documents at 101 levels of hash"
    ) or diag($err);

    eval { encode( { 0 => [ map { create_nest(98) } 1 .. 5 ] } ) };
    $err = $@;
    is( $err, '', "No error at 100 levels of hash+array+hash" );

    eval { encode( { 0 => [ map { create_nest(99) } 1 .. 5 ] } ) };
    $err = $@;
    like(
        $err,
        qr/Exceeded max object depth of 100/,
        "Hit the specified max depth encoding documents at 101 levels of hash+array+hash"
    ) or diag($err);

    # synthesize 10 and 101 levels of BSON
    my $bson_100 = encode( create_nest(100) );
    my $bson_101 = pack("l<CZ*",0,0x03,"a") . $bson_100 . "\x00";
    substr($bson_101,0,4,pack("l<",length $bson_101));

    eval { decode($bson_100) };
    $err = $@;
    is( $err, '', "No error decoding 100 levels of hash" );

    eval { decode($bson_101) };
    $err = $@;
    like(
        $err,
        qr/Exceeded max object depth of 100/,
        "Hit the specified max depth decoding documents at 101 levels of hash"
    ) or diag($err);

    # encode many Raw objects
    my $opt = {};
    eval {
        encode( { a => [ map { BSON::Raw->new(bson => encode({ b => 1 }, $opt)) } 1 .. 100 ] }, $opt );
    };
    $err = $@;
    is( $err, '', "No error encoding 100 Raw docs with same options" );
};


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

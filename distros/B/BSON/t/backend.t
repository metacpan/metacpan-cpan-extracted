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

$ENV{PERL_BSON_BACKEND} = "PPSubclass";

eval { require BSON };
is( $@, '', "BSON loads with PERL_BSON_BACKEND set" );
is(
    BSON->can("_encode_bson"),
    PPSubclass->can("_encode_bson"),
    "correct encoder sub"
);
is(
    BSON->can("_decode_bson"),
    PPSubclass->can("_decode_bson"),
    "correct decoder sub"
);

my $h = { a => 1 };

is_deeply( BSON::decode( BSON::encode($h) ),
    $h, "round trip works with codec subclass" );

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


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
use Test::Deep;

use BSON;
use BSON::Types ':all';

my $c = BSON->new;

my $pipeline = [
    {
        '$replaceRoot' => {
            'newRoot' => '$t'
        }
    },
    {
        '$addFields' => {
            'foo' => 1
        }
    }
];
my $b_array = bson_array(@$pipeline);
ok(ref $b_array eq 'BSON::Array', 'bson_array');
is_deeply(
    $c->decode_one(
        $c->encode_one({ u => $b_array })
    ),
    $c->decode_one(
        $c->encode_one({ u => $pipeline })
    ),
    'encode bson array'
);

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


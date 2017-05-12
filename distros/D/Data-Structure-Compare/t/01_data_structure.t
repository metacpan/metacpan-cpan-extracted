#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Data::Structure::Compare qw(hash_compare);

my $data1 = {
    key1 => 1,
    key2 => {
        key3 => {
            key4 => 1,
        },
    },
};

my $data2 = {
    key1 => 2,
    key2 => {
        key3 => {
            key4 => 2,
        },
    },
};

my $data3 = {
    key1 => 2,
    key2 => {
        key3 => {
            key4 => 2,
        },
    },
};

ok(hash_compare($data1, $data2), 'data structure is same');
ok(hash_compare($data1, $data3), 'data structure is same');
ok(hash_compare($data3, $data2), 'data structure is same');

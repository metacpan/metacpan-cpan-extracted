#!/usr/bin/env perl
use warnings;
use strict;
use Data::Pack ':all';
use Test::More tests => 3;
use Test::Differences;
my $h = {
    a => 1,
    b => [ 2 .. 4, undef, 6 .. 8 ],
    c => [],
    d => {},
    e => undef,
    f => (
        bless {
            f1 => undef,
            f2 => 'f2',
        },
        'Foo'
    ),
    g => {
        g1 => undef,
        g2 => undef,
        g3 => [ undef, undef, undef ],
        g4 => {
            g4a => undef,
            g4b => undef,
        },
    },
    h => [ { a => 23 }, { a => 42 } ],
};
my $hp = {
    a => 1,
    b => [ 2 .. 4, 6 .. 8 ],
    f => (bless { f2 => 'f2', }, 'Foo'),
    h => [ { a => 23 }, { a => 42 } ],
};
eq_or_diff(scalar(pack_data($h)), $hp, 'pack_data(hashref), scalar context');
my %h2 = pack_hash(%$h);
eq_or_diff(\%h2, $hp, 'pack_hash(hash), list context');

eq_or_diff(scalar(pack_data({ a => undef })), {}, 'pack_data(hashref)');

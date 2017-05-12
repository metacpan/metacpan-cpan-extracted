#!/usr/bin/env perl
use warnings;
use strict;
use Data::Pack ':all';
use Test::More tests => 1;
use Test::Differences;
my %h = (
    a => 1,
    b => [ 2 .. 4, undef, 6 .. 8 ],
    f => (
        bless {
            f1 => undef,
            f2 => 'f2',
        },
        'Foo'
    ),
);

my %h2 = (%h, a => undef, g => [ 'a'..'c' ]);
my %hp = (
    b => [ 2 .. 4, 6 .. 8 ],
    f => (bless { f2 => 'f2', }, 'Foo'),
    g => [ 'a', 'b', 'c' ],
);
eq_or_diff(scalar(pack_data(\%h2)), \%hp, 'pack overlaid hash');

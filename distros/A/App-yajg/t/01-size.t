#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

my @true = (
    [0, 1, 2, 3],
    [[], []],
    { 0 => 1 },
    { 0, 1, 2, 3 },
);

my @false = (
    undef,
    1, 2, -1, 2.3,
    0, -0, 0.0,
    'qweqwe', 'цуг', "\0", "\x{ff}\x{ffff}\x{0777}", '-0', '0.0',
    '', '0',
    \0, \'ddd', \12,
    \(@true),
    {},
    [],
    sub {0},
    qr/111/,
    bless(\my $scalar, 'class'),
    bless([],          'class'),
    bless([1, 2, 3], 'class'),
    bless({}, 'class'),
    bless({ 1 => 2 }, 'class'),
);

ok App::yajg::size($_) for @true;
ok not App::yajg::size($_) for @false;

done_testing();


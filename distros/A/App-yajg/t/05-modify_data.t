#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

my $data = {
    a => [1, 2, 3],
    b => {
        c => 1,
        d => 2,
    },
    e => undef,
};
push @{ $data->{'a'} }, $data->{'b'};

my $hooks = [sub { $_[0] = 'test' }];

my $expected = {
    a => [qw/test test test/],
    b => {
        c => 'test',
        d => 'test',
    },
    e => 'test',
};
push @{ $expected->{'a'} }, $expected->{'b'};

App::yajg::modify_data($data, $hooks);
is_deeply $data, $expected, 'Modifies correctly';

done_testing();

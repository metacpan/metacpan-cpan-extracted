#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

subtest 'no patterns at all' => sub {
    my @tests = (
        undef,
        '',
        0,
        [],
        [1, 2],
        {},
        { a => 1, b => 2 },
        \0,
        \1,
    );
    is_deeply App::yajg::filter($_), $_ for @tests;
    done_testing();
};

subtest 'niether array nor hash' => sub {
    my @tests = (
        undef,
        '',
        0,
        \0,
        \1,
        sub {0},
        qr/111/,
        bless(\my $scalar, 'class'),
        bless([],          'class'),
        bless([1, 2, 3], 'class'),
        bless({}, 'class'),
        bless({ 1 => 2 }, 'class'),
    );
    is_deeply App::yajg::filter($_, qr/1/, qr/1/), $_ for @tests;
    done_testing();
};

subtest 'one level hash' => sub {
    my $data = {
        a  => 1,
        b  => 2,
        c  => 'c',
        1  => 1,
        2  => 2,
        3  => undef,
        4  => '',
        5  => 'a',
        6  => 'b',
        '' => 'd',
    };
    my $copy    = {%$data};
    my $key_pat = qr/^\d+$/;
    my $val_pat = qr/^[a-z]+$/;
    my $key     = {
        1 => 1,
        2 => 2,
        3 => undef,
        4 => '',
        5 => 'a',
        6 => 'b',
    };
    my $val = {
        c  => 'c',
        5  => 'a',
        6  => 'b',
        '' => 'd',
    };
    my $key_val = {
        5 => 'a',
        6 => 'b',
    };
    is_deeply App::yajg::filter($data, $key_pat), $key, 'key grep';
    is_deeply App::yajg::filter($data, undef,    $val_pat), $val,     'val grep';
    is_deeply App::yajg::filter($data, $key_pat, $val_pat), $key_val, 'key and val grep';
    is_deeply $data, $copy, 'Hash has not been modified after all';
    done_testing();
};

subtest 'one level array' => sub {
    my $data    = [1, 2, 3, undef, 0, '', qw/a b c/];
    my $copy    = [@$data];
    my $key_pat = qr/^[a-z]+$/;
    my $val_pat = qr/^\d+$/;
    my $val     = [1, 2, 3, 0];
    is_deeply App::yajg::filter($data, $key_pat), [], 'key grep';
    is_deeply App::yajg::filter($data, undef,    $val_pat), $val, 'val grep';
    is_deeply App::yajg::filter($data, $key_pat, $val_pat), $val, 'key and val grep';
    is_deeply $data, $copy, 'Array has not been modified after all';
    done_testing();
};

subtest 'key pattern' => sub {
    my @tests = (
        {
            data => {
                1 => {},
                a => { 2 => undef, 3 => [], c => { f => 2, 2 => 0 } },
            },
            pattern  => qr/^\d+$/,
            expected => {
                1 => {},
                a => { 2 => undef, 3 => [], c => { 2 => 0 } },
            },
        },
        {
            data => [
                [{ 10 => {} }],
                1,
                0,
                [],
                { 2 => undef, 3 => [], c => { f => 2, 2 => 0 } },
            ],
            pattern  => qr/^\d+$/,
            expected => [
                [{ 10 => {} }],
                { 2 => undef, 3 => [], c => { 2 => 0 } },
            ],
        },
        {
            data => [
                [{ a0 => {} }],
                1,
                0,
                [],
                { v2 => undef, b3 => [], c => { df => 2, d2 => 0 } },
            ],
            pattern  => qr/^\d+$/,
            expected => [],
        },
        {
            data => {
                c1 => {},
                a => { s => undef, q => [], c => { f => 2, w => 0 } },
            },
            pattern  => qr/^\d+$/,
            expected => {},
        },
    );
    for (@tests) {
        is_deeply App::yajg::filter($_->{'data'}, $_->{'pattern'}), $_->{'expected'};
    }
    done_testing();
};

subtest 'value pattern' => sub {
    my @tests = (
        {
            data => {
                1 => {},
                a => { 2 => undef, 3 => [], c => { f => 2, 2 => 0, '' => 1 } },
            },
            pattern  => qr/^\d+$/,
            expected => {
                a => { c => { f => 2, 2 => 0, '' => 1 } },
            },
        },
        {
            data => [
                [{ 10 => {} }],
                1,
                undef,
                0,
                ['a', 'b', 3],
                { 2 => undef, 3 => [4], c => { f => 2, 2 => 0 } },
            ],
            pattern  => qr/^\d+$/,
            expected => [
                1,
                0,
                [3],
                { 3 => [4], c => { f => 2, 2 => 0 } },
            ],
        },
        {
            data => [
                [{ a0 => {} }],
                [qw/a b v n/],
                { v2 => undef, b3 => [], c => { df => 's', d2 => 'f' } },
            ],
            pattern  => qr/^\d+$/,
            expected => [],
        },
        {
            data => {
                c1 => {},
                a => { s => undef, q => [qw/d d d/], c => { f => '', w => 'd' } },
            },
            pattern  => qr/^\d+$/,
            expected => {},
        },
    );
    for (@tests) {
        is_deeply App::yajg::filter($_->{'data'}, undef, $_->{'pattern'}), $_->{'expected'};
    }
    done_testing();
};

subtest 'value pattern invert' => sub {
    my @tests = (
        {
            data => {
                1 => {},
                a => { 2 => undef, 3 => [], c => { f => 2, 2 => 0, '' => 1 } },
            },
            pattern  => qr/^\d+$/,
            expected => {
                1 => {},
                a => { 2 => undef, 3 => [] },
            },
        },
        {
            data => [
                [{ 10 => {} }],
                1,
                undef,
                0,
                ['a', 'b', 3],
                { 2 => undef, 3 => [4], c => { f => 2, 2 => 0 } },
            ],
            pattern  => qr/^\d+$/,
            expected => [
                [{ 10 => {} }],
                undef,
                ['a', 'b'],
                { 2 => undef },
            ],
        },
        {
            data => [
                [{ a0 => {} }],
                [qw/a b v n/],
                { v2 => undef, b3 => [], c => { df => 's', d2 => 'f' } },
            ],
            pattern  => qr/^\d+$/,
            expected => [
                [{ a0 => {} }],
                [qw/a b v n/],
                { v2 => undef, b3 => [], c => { df => 's', d2 => 'f' } },
            ],
        },
        {
            data => {
                c1 => {},
                a => { s => undef, q => [qw/d d d/], c => { f => '', w => 'd' } },
            },
            pattern  => qr/^\d+$/,
            expected => {
                c1 => {},
                a => { s => undef, q => [qw/d d d/], c => { f => '', w => 'd' } },
            },
        },
    );
    for (@tests) {
        is_deeply App::yajg::filter($_->{'data'}, undef, $_->{'pattern'}, 1), $_->{'expected'};
    }
    done_testing();
};

subtest 'key and value pattern' => sub {
    my @tests = (
        {
            data => {
                1 => {},
                a => { 2 => undef, 3 => [], c => { f => 2, 2 => 0, '' => 1 } },
            },
            key_pat  => qr/^[a-f]$/,
            val_pat  => qr/^\d+$/,
            expected => {
                a => { c => { f => 2 } },
            },
        },
        {
            data => [
                [{ 10 => {} }],
                1,
                undef,
                0,
                ['a', 'b', 3],
                { 2 => undef, 3 => [4], c => { f => 2, 2 => 0 } },
            ],
            key_pat  => qr/^[a-f]$/,
            val_pat  => qr/^\d+$/,
            expected => [
                1,
                0,
                [3],
                { 3 => [4], c => { f => 2 } },
            ],
        },
        {
            data => [
                [{ a0 => {} }],
                [qw/a b v n/],
                { v2 => undef, b3 => [], c => { df => 's', d2 => 'f' } },
            ],
            key_pat  => qr/^[a-f]$/,
            val_pat  => qr/^\d+$/,
            expected => [],
        },
        {
            data => {
                c1 => {},
                a => { s => undef, q => [qw/d d d/], c => { f => '', w => 'd' } },
            },
            key_pat  => qr/^[a-f]$/,
            val_pat  => qr/^\d+$/,
            expected => {},
        },
    );
    for (@tests) {
        is_deeply App::yajg::filter($_->{'data'}, $_->{'key_pat'}, $_->{'val_pat'}), $_->{'expected'};
    }
    done_testing();
};

done_testing();

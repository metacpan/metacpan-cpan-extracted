#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

subtest 'no path' => sub {
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
    is_deeply App::yajg::select_by_path($_), $_ for @tests;
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
    ok not defined App::yajg::select_by_path($_, 1) for @tests;
    done_testing();
};

subtest 'one level select in hash' => sub {
    my $hash = {
        a  => 1,
        b  => [1, 2],
        1  => { a => 1, b => 2 },
        2  => 4,
        c  => undef,
        d  => 0,
        e  => '',
        '' => 'emprty',
    };
    my $copy = {%$hash};
    for (sort(keys %$hash), 'not in hash') {
        my @select = ({
                type => 'HASH',
                val  => $_,
        });
        is_deeply(
            App::yajg::select_by_path($hash, @select),
            exists $hash->{$_} ? { $_ => $hash->{$_} } : undef,
            'Type HASH'
        );
    }
    for (sort(keys %$hash), 'not in hash') {
        my @select = ({
                type => 'SLICE',
                val => [1, 2],
        });
        ok not(defined App::yajg::select_by_path($hash, @select)), 'Type SLICE';
    }
    for my $re (qr/^\d+$/, qr/^[a-z]+$/, qr/^abcdefgh$/) {
        my @select = ({
                type => 'REGEXP',
                val  => $re,
        });
        my $expected = { map { $_ => $hash->{$_} } grep {m/$re/} keys %$hash };
        $expected = undef unless %$expected;
        is_deeply(
            App::yajg::select_by_path($hash, @select),
            $expected,
            'Type REGEXP'
        );
    }
    for (sort(keys %$hash), 'not in hash') {
        my @select = ({
                type => 'UNKNOWN',
                val  => $_,
        });
        is_deeply(
            App::yajg::select_by_path($hash, @select),
            exists $hash->{$_} ? { $_ => $hash->{$_} } : undef,
            'Type UNKNOWN'
        );
    }
    is_deeply $hash, $copy, 'Hash has not been modified after all';
    done_testing();
};

subtest 'one level select in hash with ic' => sub {
    my $hash = {
        a => 1,
        b => [1, 2],
        A => { a => 1, b => 2 },
        B => 4,
    };
    my $copy = {%$hash};
    for my $key (qw/a b/, 'not in hash') {
        my @select = ({
                type => 'HASH_IC',
                val  => $key,
        });
        my $expected = { map { $_ => $hash->{$_} } grep { $key eq lc $_ } keys %$hash };
        $expected = undef unless %$expected;
        is_deeply(
            App::yajg::select_by_path($hash, @select),
            $expected,
            'Type HASH_IC'
        );
        $_->{'type'} = 'UNKNOWN_IC' for @select;
        is_deeply(
            App::yajg::select_by_path($hash, @select),
            $expected,
            'Type UNKNOWN_IC'
        );
    }
    is_deeply $hash, $copy, 'Hash has not been modified after all';
    done_testing();
};

subtest 'one level select in array' => sub {
    my $array = [
        1,
        [1, 2],
        { a => 1, b => 2 },
        4,
        undef,
        0,
        '',
        'emprty',
    ];
    my $copy = [@$array];
    for ((0 .. $#$array), 100) {
        my @select = ({
                type => 'HASH',
                val  => $_,
        });
        ok not(defined App::yajg::select_by_path($array, @select)), 'Type HASH';
    }
    for ([0 .. $#$array], [3, 4, 2, 1, 2, 1], [-1, -2], [0, 1], [100, 200]) {
        my @select = ({
                type => 'SLICE',
                val  => $_,
        });
        my $expected = [@$array[@$_]];
        $expected = undef unless @$expected;
        is_deeply(
            App::yajg::select_by_path($array, @select),
            $expected,
            'Type SLICE'
        );
    }
    for my $re (qr/^\d+$/, qr/^[a-z]+$/, qr/^abcdefgh$/, qr/^[0345]$/) {
        my @select = ({
                type => 'REGEXP',
                val  => $re,
        });
        my $expected = [map { $array->[$_] } grep {m/$re/} keys @$array];
        $expected = undef unless @$expected;
        is_deeply(
            App::yajg::select_by_path($array, @select),
            $expected,
            'Type REGEXP'
        );
    }
    for ((0 .. $#$array), 100, -1, -2) {
        my @select = ({
                type => 'UNKNOWN',
                val  => $_,
        });
        is_deeply(
            App::yajg::select_by_path($array, @select),
            exists $array->[$_] ? [$array->[$_]] : undef,
            'Type UNKNOWN'
        );
        $_->{'type'} = 'UNKNOWN_IC' for @select;
        is_deeply(
            App::yajg::select_by_path($array, @select),
            exists $array->[$_] ? [$array->[$_]] : undef,
            'Type UNKNOWN_IC'
        );
    }
    is_deeply $array, $copy, 'Array has not been modified after all';
    done_testing();
};

subtest 'Multilevel select' => sub {
    my $structure = {
        'HASH' => {
            a => 1,
            b => 2,
            c => 3,
            d => undef,
            e => [1, 2, 3, 4, undef],
        },
        'ARRAY' => [
            { a => 1, b => 2 },
            [1, 2, 3, undef],
            undef,
            'a',
            'b',
            { c => 4, b => undef },
        ],
    };
    # { select => [], expected => $expected }
    my @tests = (
        {
            select => [App::yajg::parse_select('HASH.a')],
            expected => { HASH => { a => 1 } },
        },
        {
            select => [App::yajg::parse_select('HASH.d')],
            expected => { HASH => { d => undef } },
        },
        {
            select => [App::yajg::parse_select('HASH.{d}')],
            expected => { HASH => { d => undef } },
        },
        {
            select   => [App::yajg::parse_select('HASH.[1]')],
            expected => undef,
        },
        {
            select => [App::yajg::parse_select('{HASH}./e/.-1')],
            expected => { HASH => { e => [undef] } },,
        },
        {
            select => [App::yajg::parse_select('{HASH}./e/.[-1, -1]')],
            expected => { HASH => { e => [undef, undef] } },
        },
        {
            select   => [App::yajg::parse_select('[1]')],
            expected => undef,
        },
        {
            select   => [App::yajg::parse_select('{ARRAY}.{1}')],
            expected => undef,
        },
        {
            select => [App::yajg::parse_select('{ARRAY}.[1]./\d+/')],
            expected => { ARRAY => [[1, 2, 3, undef]] },
        },
        {
            select => [App::yajg::parse_select('{ARRAY}./\d+/.b')],
            expected => { ARRAY => [{ b => 2 }, { b => undef }] },
        },
        {
            select => [App::yajg::parse_select('{ARRAY}./\d+/./[bc]/')],
            expected => { ARRAY => [{ b => 2 }, { b => undef, c => 4 }] },
        },
    );
    for (@tests) {
        is_deeply(
            App::yajg::select_by_path($structure, @{ $_->{'select'} }),
            $_->{'expected'}
        );
    }
    done_testing();
};

done_testing();

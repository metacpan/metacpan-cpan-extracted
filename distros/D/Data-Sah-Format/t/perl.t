#!perl

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah::Format;
use Test::More 0.98;
use Test::Needs;

subtest iso8601_date => sub {
    test_format(
        format => 'iso8601_date',
        data   => [1465789176  , 1465775176  , -1, "foo", []],
        fdata  => ["2016-06-13", "2016-06-12", -1, "foo", []],
    );
    subtest "opt:format_datetime" => sub {
        test_needs "DateTime";
        my $dt = DateTime->new(
            year=>2016, month=>6, day=>13, hour=>6, minute=>0, second=>0,
            time_zone => 'Asia/Jakarta');
        test_format(
            name   => 'opt:format_datetime=0',
            format => 'iso8601_date',
            formatter_args => {format_datetime=>0},
            data   => [$dt],
            fdata  => [$dt],
        );
        test_format(
            name   => 'opt:format_datetime=1',
            format => 'iso8601_date',
            data   => [$dt],
            fdata  => ["2016-06-12"],
        );
    };
    subtest "opt:format_timemoment" => sub {
        test_needs "Time::Moment";
        my $tm = Time::Moment->new(
            year=>2016, month=>6, day=>13, hour=>6, minute=>0, second=>0,
            offset => 7*60);
        test_format(
            name   => 'opt:format_timemoment=0',
            format => 'iso8601_date',
            formatter_args => {format_timemoment=>0},
            data   => [$tm],
            fdata  => [$tm],
        );
        test_format(
            name   => 'opt:format_timemoment=1',
            format => 'iso8601_date',
            data   => [$tm],
            fdata  => ["2016-06-12"],
        );
    };
};

subtest iso8601_datetime => sub {
    test_format(
        format => 'iso8601_datetime',
        data   => [1465789176  , 1465775176  , -1, "foo", []],
        fdata  => ["2016-06-13T03:39:36Z", "2016-06-12T23:46:16Z", -1, "foo", []],
    );
    subtest "opt:format_datetime" => sub {
        test_needs "DateTime";
        my $dt = DateTime->new(
            year=>2016, month=>6, day=>13, hour=>6, minute=>0, second=>0,
            time_zone => 'Asia/Jakarta');
        test_format(
            name   => 'opt:format_datetime=0',
            format => 'iso8601_datetime',
            formatter_args => {format_datetime=>0},
            data   => [$dt],
            fdata  => [$dt],
        );
        test_format(
            name   => 'opt:format_datetime=1',
            format => 'iso8601_datetime',
            data   => [$dt],
            fdata  => ["2016-06-12T23:00:00Z"],
        );
    };
    subtest "opt:format_timemoment" => sub {
        test_needs "Time::Moment";
        my $tm = Time::Moment->new(
            year=>2016, month=>6, day=>13, hour=>6, minute=>0, second=>0,
            offset => 7*60);
        test_format(
            name   => 'opt:format_timemoment=0',
            format => 'iso8601_datetime',
            formatter_args => {format_timemoment=>0},
            data   => [$tm],
            fdata  => [$tm],
        );
        test_format(
            name   => 'opt:format_timemoment=1',
            format => 'iso8601_datetime',
            data   => [$tm],
            fdata  => ["2016-06-12T23:00:00Z"],
        );
    };
};

done_testing;

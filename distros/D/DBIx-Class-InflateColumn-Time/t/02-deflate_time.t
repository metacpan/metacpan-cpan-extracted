#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Data::Dumper;

use DateTime;
use DateTime::Duration;

use DBIx::Class::InflateColumn::Time;

subtest "Deflate Positive Less Than 24 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => 1,
        minutes => 2,
        seconds => 3,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '01:02:03', "Check Time Format");
};

subtest "Deflate Positive Greater Than 24 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => 27,
        minutes => 23,
        seconds => 45,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '27:23:45', "Check Time Format");
};

subtest "Deflate Positive Greater Than 24 Hour Time With Days" => sub {
    my $duration = DateTime::Duration->new({
        days    => 1,
        hours   => 27,
        minutes => 23,
        seconds => 45,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '51:23:45', "Check Time Format");

};

subtest "Deflate Positive Greater Than 100 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => 123,
        minutes => 45,
        seconds => 6,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '123:45:06', "Check Time Format");
};

subtest "Deflate Negative Less Than 24 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => -1,
        minutes => -2,
        seconds => -3,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '-01:02:03', "Check Time Format");
};

subtest "Deflate Negative Greater Than 24 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => -27,
        minutes => -23,
        seconds => -45,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '-27:23:45', "Check Time Format");
};

subtest "Deflate Negative Greater Than 24 Hour Time With Days" => sub {
    my $duration = DateTime::Duration->new({
        days    => -1,
        hours   => -27,
        minutes => -23,
        seconds => -45,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '-51:23:45', "Check Time Format");

};

subtest "Deflate Negative Greater Than 100 Hour Time" => sub {
    my $duration = DateTime::Duration->new({
        hours   => -123,
        minutes => -45,
        seconds => -6,
    });

    my $time = DBIx::Class::InflateColumn::Time::_deflate($duration);

    cmp_ok($time, 'eq', '-123:45:06', "Check Time Format");
};

done_testing;

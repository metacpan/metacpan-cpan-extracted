#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Data::Dumper;

use DateTime;
use DateTime::Duration;

use DBIx::Class::InflateColumn::Time;

subtest "Inflate Positive Less Than 24 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('01:02:03');

    ok($duration->is_positive, "Check Sign");
    cmp_ok($duration->hours,   '==', 1, "Check Hours");
    cmp_ok($duration->minutes, '==', 2, "Check Minutes");
    cmp_ok($duration->seconds, '==', 3, "Check Seconds");
};

subtest "Inflate Positive Greater Than 24 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('27:34:56');

    ok($duration->is_positive, "Check Sign");
    cmp_ok($duration->hours,   '==', 27, "Check Hours");
    cmp_ok($duration->minutes, '==', 34, "Check Minutes");
    cmp_ok($duration->seconds, '==', 56, "Check Seconds");
};

subtest "Inflate Positive Greater Than 100 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('123:45:06');

    ok($duration->is_positive, "Check Sign");
    cmp_ok($duration->hours,   '==', 123, "Check Hours");
    cmp_ok($duration->minutes, '==', 45, "Check Minutes");
    cmp_ok($duration->seconds, '==', 06, "Check Seconds");

};

subtest "Inflate Negative Less Than 24 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('-01:02:03');

    ok($duration->is_negative, "Check Sign");
    cmp_ok($duration->hours,   '==', 1, "Check Hours");
    cmp_ok($duration->minutes, '==', 2, "Check Minutes");
    cmp_ok($duration->seconds, '==', 3, "Check Seconds");
};

subtest "Inflate Negative Greater Than 24 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('-27:34:56');

    ok($duration->is_negative, "Check Sign");
    cmp_ok($duration->hours,   '==', 27, "Check Hours");
    cmp_ok($duration->minutes, '==', 34, "Check Minutes");
    cmp_ok($duration->seconds, '==', 56, "Check Seconds");
};

subtest "Inflate Negative Greater Than 100 Hour Time" => sub {
    my $duration = DBIx::Class::InflateColumn::Time::_inflate('-123:45:06');

    ok($duration->is_negative, "Check Sign");
    cmp_ok($duration->hours,   '==', 123, "Check Hours");
    cmp_ok($duration->minutes, '==', 45, "Check Minutes");
    cmp_ok($duration->seconds, '==', 06, "Check Seconds");

};


done_testing;

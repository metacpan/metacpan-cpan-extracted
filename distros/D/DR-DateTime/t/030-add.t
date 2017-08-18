#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 28;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}


for my $t (DR::DateTime->parse('2017-08-17 10:34:58.5+07')) {
    isa_ok $t => DR::DateTime::, 'parsed fixed time the other time zone';
    is $t->tz, '+0700', 'tz';
    is $t->epoch, 1502940898, 'epoch';
    is $t->strftime('%F %T%z'), '2017-08-17 10:34:58+0700', 'strftime';

    is $t->year, 2017, 'year';
    is $t->month, 8, 'Month';
    is $t->day, 17, 'Day';
    is $t->day_of_week, 4, 'day of week';
    is $t->quarter, 3, 'quarter';

    is $t->hour, 10, 'hour';
    is $t->minute, 34, 'minute';
    is $t->second, 58, 'second';
    is $t->nanosecond, 500_000_000,
        'nanosecond';
    is $t->hms('.'), '10.34.58', 'hms';
    is $t->ymd('/'), '2017/08/17', 'ymd';

    is $t->time_zone, $t->tz, 'time_zone';

    my $epoch = $t->epoch;
    $t->add(second => 2);
    is $t->epoch, $epoch + 2, 'epoch after add';
    is $t->strftime('%F %T.%N %z'),
        '2017-08-17 10:35:00.500000000 +0700',
        'strftime after add';
    $epoch = $t->epoch;

    $t->add(month => 2);
    is $t->strftime('%F %T.%N %z'),
        '2017-10-17 10:35:00.500000000 +0700',
        'strftime after add';

    $t->add(month => 3);
    is $t->strftime('%F %T.%N %z'),
        '2018-01-17 10:35:00.500000000 +0700',
        'strftime after add';
}

for my $t (DR::DateTime->parse('2017-08-31 23:33:32+0300')) {
    isa_ok $t => DR::DateTime::, 'parsed 31 aug';
    $t->add(month => 1);
    is $t->strftime('%F %T.%N%z'),
        '2017-09-30 23:33:32.0+0300',
        'strftime after add';
}

for my $t (DR::DateTime->parse('2016-02-29 23:33:32+0300')) {
    is $t->day, 29, '29 feb';
    isa_ok $t => DR::DateTime::, 'parsed 29 feb';
    $t->add(year => 1);
    is $t->strftime('%F %T.%N%z'),
        '2017-02-28 23:33:32.0+0300',
        'strftime after add';
}

for my $t (DR::DateTime->parse('2017-08-17 23:33:32+0300')) {
    isa_ok $t => DR::DateTime::, 'parsed 31 aug';
    $t->add(month => 1, year => 1, day => 30, hour => 1);
    is $t->strftime('%F %T.%N%z'),
        '2018-10-17 00:33:32.0+0300',
        'strftime after add';
}

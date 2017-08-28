#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 71;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
    use_ok 'POSIX', 'strftime';
}

my $now = time;

for my $t (DR::DateTime->parse(strftime '%F %T+0000', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}
for my $t (DR::DateTime->parse(strftime '%F %T+0100', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now - 3600, 'epoch';
    is $t->tz, '+0100', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0100', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T -1', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed tz 1 length';
    is $t->epoch, $now + 3600, 'epoch';
    is $t->tz, '-0100', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T-0100', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %H:%M', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed GMT';
    is $t->epoch, $now - $now % 60, 'epoch';
    is $t->tz, '+0000', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %H:%M:00+0000', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed local tz';
    is $t->epoch, $now, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime("%F %T%z"),
        strftime('%F %T%z', localtime $now), 'strftime';
}

for my $t (DR::DateTime->parse(strftime '%FT%T.1234567 %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float';
    is $t->epoch, $now, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T%z', localtime $now),
        'strftime';
    is $t->strftime('%N'),
        int(1_000_000_000 * ($now + '.1234567' - $now)),
        'nanoseconds'
}

for my $t (DR::DateTime->parse(strftime '%d.%m.%Y %T.1234567 %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float';
    is $t->epoch, $now, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T%z', localtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%d.%m.%Y %T.1234567', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float russian format';
    is $t->epoch, $now, 'epoch';
    is $t->fepoch, $now + .1234567, 'epoch';
    is $t->tz, '+0000', 'tz';
    
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse('2017-08-17 10:34:58+03')) {
    isa_ok $t => DR::DateTime::, 'parsed fixed time';
    is $t->tz, '+0300', 'tz';
    is $t->epoch, 1502955298, 'epoch';
    is $t->strftime('%F %T%z'), '2017-08-17 10:34:58+0300', 'strftime';
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
}

for my $t (DR::DateTime->parse('2017-08-17 10:34')) {
    isa_ok $t => DR::DateTime::, 'parsed wo second';
    is $t->hour, 10, 'hour';
    is $t->minute, 34, 'minute';
}

for my $t (DR::DateTime->parse('2017-08-17')) {
    isa_ok $t => DR::DateTime::, 'parsed wo second';
    is $t->hour, 0, 'hour';
    is $t->minute, 0, 'minute';
}

for my $t (DR::DateTime->parse('21.08.2017 12:00:00 +0300')) {
    isa_ok $t => DR::DateTime::, 'parsed real case';
    is $t->hour, 12, 'hour';
}

for my $t (DR::DateTime->parse($now)) {
    isa_ok $t => DR::DateTime::, 'parsed timestamp';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
}

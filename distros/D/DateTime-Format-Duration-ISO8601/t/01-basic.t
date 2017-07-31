#!perl

use 5.010001;
use strict;
use warnings;

use DateTime::Duration;
use DateTime::Format::Duration::ISO8601;
use Test::More 0.98;

my $f = DateTime::Format::Duration::ISO8601->new;

is($f->format_duration(DateTime::Duration->new()), "PT0H0M0S", 'empty duration');
is($f->format_duration(DateTime::Duration->new(years=>1)), "P1Y", 'one year');
is($f->format_duration(DateTime::Duration->new(hours=>2)), "PT2H", 'two hours');
is($f->format_duration(DateTime::Duration->new(years=>1, months=>2, weeks=>2, days=>7+4, hours=>5, minutes=>6, seconds=>7, nanoseconds=>800_000_000)), "P1Y2M25DT5H6M7.8S", 'all duration fields');

eval { $f->format_duration("123") };
ok $@ =~ m[not a DateTime::Duration instance], 'invalid dt arg';

my $d = $f->parse_duration('P1Y1M1DT1H1M1.000000001S');

is $d->years, 1, 'years parsed';
is $d->months, 1, 'months parsed';
is $d->days, 1, 'days parsed';
is $d->hours, 1, 'hours parsed';
is $d->minutes, 1, 'minutes parsed';
is $d->seconds, 1, 'seconds parsed';
is $d->nanoseconds, 1, 'nanoseconds parsed';

$d = $f->parse_duration('P13MT61M');

is $d->years, 1, 'months overflow';
is $d->months, 1, 'modular months';
is $d->hours, 1, 'minutes overflow';
is $d->hours, 1, 'modular minutes';

eval { $f->parse_duration('abc') };
ok $@ =~ m[abc.*not a valid], 'parse failure error message';

my $error;

eval {
    DateTime::Format::Duration::ISO8601->new(
        on_error => sub { $error = shift }
    )->parse_duration('xyz');
};

ok defined $error, 'error set via on_error callback';
ok $error =~ m[xyz.*not a valid], 'parse failure error callback message';

eval { $f->parse_duration('RP1Y') };
ok $@ =~ m[repetitions are not supported], 'repetition durations error';

done_testing;

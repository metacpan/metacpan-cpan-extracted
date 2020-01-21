#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese cmpthese/;
use Date;
use Time::Moment;
use DateTime::TimeZone;

say "START";
my $time = -1;

say "new empty";
cmpthese($time, {
    Date           => sub { Date::date() },
    "Time::Moment" => sub { Time::Moment->new },
});
say;

say "new with current time";
cmpthese($time, {
    Date           => sub { Date::now() },
    Date_hires     => sub { Date::now_hires() },
    "Time::Moment" => sub { Time::Moment->now },
});
say;

say "new from epoch";
cmpthese($time, {
    Date           => sub { Date::date(1000000000) },
    "Time::Moment" => sub { Time::Moment->from_epoch(1000000000) },
});
say;

say "new from string";
cmpthese($time, {
    Date           => sub { Date::date("2019-01-01T23:59:59Z") },
    "Time::Moment" => sub { Time::Moment->from_epoch("2019-01-01T23:59:59Z") },
});
say;

say "new from named YMDHMS";
cmpthese($time, {
    Date           => sub { Date::date_ymd(year => 2019, month => 1, day => 1, hour => 23, min => 59, sec => 59, mksec => 123456) },
    "Time::Moment" => sub { Time::Moment->new(year => 2019, month => 1, day => 1, hour => 23, minute => 59, second => 59, nanosecond => 123456000) },
});
say;

say "today (now+truncate)";
{
    my $d = Date::now();
    my $tm = Time::Moment->now();
    cmpthese($time, {
        Date           => sub { Date::today() },
        "Time::Moment" => sub { Time::Moment->now->at_midnight },
    });
}
say;

say "adding 1 relative";
{
    my $d = Date::now();
    my $tm = Time::Moment->now();
    cmpthese($time, {
        Date           => sub { $d += HOUR },
        "Time::Moment" => sub { $tm = $tm->plus_hours(1) },
    });
}
say;

say "adding many relatives";
{
    my $d = Date::now();
    my $tm = Time::Moment->now();
    cmpthese($time, {
        Date           => sub { $d += "1D 1h 1m 1s" },
        "Time::Moment" => sub { $tm = $tm->plus_days(1)->plus_hours(1)->plus_minutes(1)->plus_seconds(1) },
    });
}
say;

say "converting epoch<->YMDHMS with date operations";
{
    my $d = Date::now();
    my $tm = Time::Moment->now();
    cmpthese($time, {
        Date           => sub { $d += 1; $d->year; $d += DAY; $d->epoch },
        "Time::Moment" => sub { $tm = $tm->plus_seconds(1); $tm->year; $tm = $tm->plus_days(1); $tm->epoch },
    });
}
say;

say "using timezones";
cmpthese($time, {
    Date           => sub { Date::date_ymd(2012, 12, 24, 15, 0, 0, 0, 'America/New_York') },
    "Time::Moment" => sub {
        my $tm = Time::Moment->new(
            year   => 2012,
            month  => 12,
            day    => 24,
            hour   => 15
        );
        my $zone   = DateTime::TimeZone->new(name => 'America/New_York');
        my $offset = $zone->offset_for_datetime($tm) / 60;
        $tm->with_offset_same_instant($offset);
    },
});
say;

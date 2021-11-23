use strict;
use warnings;

use Test::More tests => 2017;
use Test::NoWarnings;
use Date::Utility;

# How many ways can I slice and dice a date?
my %results = (
    huey => {
        epoch                       => 1278382486,
        datetime                    => '2010-07-06 02:14:46',
        datetime_ddmmmyy_hhmmss_TZ  => '6-Jul-10 02:14:46GMT',
        datetime_yyyymmdd_hhmmss    => '2010-07-06 02:14:46',
        datetime_iso8601            => '2010-07-06T02:14:46Z',
        datetime_yyyymmdd_hhmmss_TZ => '2010-07-06 02:14:46GMT',
        date                        => '2010-07-06',
        date_ddmmyy                 => '06-07-10',
        date_ddmmyyyy               => '06-07-2010',
        date_ddmmmyyyy              => '6-Jul-2010',
        date_ddmonthyyyy            => '6 July 2010',
        date_yyyymmdd               => '2010-07-06',
        day_as_string               => 'Tue',
        db_timestamp                => '2010-07-06 02:14:46',
        full_day_name               => 'Tuesday',
        is_dst_in_zone              => 1,
        is_a_weekday                => 1,
        is_a_weekend                => 0,
        iso8601                     => '2010-07-06T02:14:46Z',
        month_as_string             => 'Jul',
        full_month_name             => 'July',
        timezone_offset             => '-4h',
        http_expires_format         => 'Tue, 06 Jul 2010 02:14:46 GMT',
        time                        => '02h14',
        time_hhmm                   => '02:14',
        time_hhmmss                 => '02:14:46',
        time_cutoff                 => 'UTC 02:14',
        timezone                    => 'GMT',
        second                      => '46',
        quarter_of_year             => '3',
        minute                      => '14',
        hour                        => '02',
        day_of_month                => 6,
        month                       => 7,
        year                        => 2010,
        year_in_two_digit           => 10,
        day_of_week                 => 2,
        day_of_year                 => 187,
        days_since_epoch            => 14796,
        seconds_after_midnight      => 8086,
        days_in_month               => 31,
    },
    dewey => {
        epoch                       => 915321540,
        datetime                    => '1999-01-02 23:59:00',
        datetime_ddmmmyy_hhmmss_TZ  => '2-Jan-99 23:59:00GMT',
        datetime_yyyymmdd_hhmmss    => '1999-01-02 23:59:00',
        datetime_iso8601            => '1999-01-02T23:59:00Z',
        datetime_yyyymmdd_hhmmss_TZ => '1999-01-02 23:59:00GMT',
        date                        => '1999-01-02',
        date_ddmmyy                 => '02-01-99',
        date_ddmmyyyy               => '02-01-1999',
        date_ddmmmyyyy              => '2-Jan-1999',
        date_ddmonthyyyy            => '2 January 1999',
        date_yyyymmdd               => '1999-01-02',
        day_as_string               => 'Sat',
        db_timestamp                => '1999-01-02 23:59:00',
        full_day_name               => 'Saturday',
        is_a_weekday                => 0,
        is_a_weekend                => 1,
        is_dst_in_zone              => 0,
        iso8601                     => '1999-01-02T23:59:00Z',
        month_as_string             => 'Jan',
        full_month_name             => 'January',
        http_expires_format         => 'Sat, 02 Jan 1999 23:59:00 GMT',
        time                        => '23h59',
        time_hhmm                   => '23:59',
        time_hhmmss                 => '23:59:00',
        time_cutoff                 => 'UTC 23:59',
        timezone                    => 'GMT',
        second                      => '00',
        quarter_of_year             => '1',
        minute                      => '59',
        hour                        => '23',
        day_of_month                => 2,
        month                       => 1,
        timezone_offset             => '-5h',
        year                        => 1999,
        year_in_two_digit           => 99,
        day_of_week                 => 6,
        day_of_year                 => 2,
        days_since_epoch            => 10593,
        seconds_after_midnight      => 86340,
        days_in_month               => 31,
    },
    louie => {
        epoch                       => 1310906096,
        datetime                    => '2011-07-17 12:34:56',
        datetime_ddmmmyy_hhmmss_TZ  => '17-Jul-11 12:34:56GMT',
        datetime_yyyymmdd_hhmmss    => '2011-07-17 12:34:56',
        datetime_iso8601            => '2011-07-17T12:34:56Z',
        datetime_yyyymmdd_hhmmss_TZ => '2011-07-17 12:34:56GMT',
        date                        => '2011-07-17',
        date_ddmmyy                 => '17-07-11',
        date_ddmmyyyy               => '17-07-2011',
        date_ddmmmyyyy              => '17-Jul-2011',
        date_ddmonthyyyy            => '17 July 2011',
        date_yyyymmdd               => '2011-07-17',
        day_as_string               => 'Sun',
        db_timestamp                => '2011-07-17 12:34:56',
        full_day_name               => 'Sunday',
        is_a_weekday                => 0,
        is_a_weekend                => 1,
        is_dst_in_zone              => 1,
        iso8601                     => '2011-07-17T12:34:56Z',
        month_as_string             => 'Jul',
        full_month_name             => 'July',
        http_expires_format         => 'Sun, 17 Jul 2011 12:34:56 GMT',
        time                        => '12h34',
        time_hhmm                   => '12:34',
        time_hhmmss                 => '12:34:56',
        time_cutoff                 => 'UTC 12:34',
        timezone                    => 'GMT',
        second                      => '56',
        quarter_of_year             => '3',
        minute                      => '34',
        hour                        => '12',
        day_of_month                => 17,
        month                       => 7,
        timezone_offset             => '-4h',
        year                        => 2011,
        year_in_two_digit           => 11,
        day_of_week                 => 0,
        day_of_year                 => 198,
        days_since_epoch            => 15172,
        seconds_after_midnight      => 45296,
        days_in_month               => 31,
    },
);

my @testcases = ({
        epoch      => 1278382486,
        results_in => 'huey',
    },
    {
        datetime   => '6-Jul-10 02:14:46GMT',
        results_in => 'huey',
    },
    {
        datetime   => '6-Jul-10 02:14:46',
        results_in => 'huey',
    },
    {
        datetime   => '6-Jul-10 02h14:46',
        results_in => 'huey',
    },
    {
        datetime   => '6-Jul-10 2:14:46',
        results_in => 'huey',
    },
    {
        datetime   => '6-Jul-10 2h14:46',
        results_in => 'huey',
    },
    {
        datetime   => '2010-07-06 02:14:46',
        results_in => 'huey',
    },
    {
        datetime   => '2010-07-06 02:14:46.76402',
        results_in => 'huey',
    },
    {
        datetime   => '2010-07-06T02:14:46',
        results_in => 'huey',
    },
    {
        datetime   => '2010-07-06T02:14:46Z',
        results_in => 'huey',
    },
    {
        datetime   => '20100706021446',
        results_in => 'huey',
    },
    {
        datetime   => '2-Jan-99 23h59GMT',
        results_in => 'dewey',
    },
    {
        datetime   => '2-Jan-99 23h59',
        results_in => 'dewey',
    },
    {
        datetime   => '2-Jan-99 23:59',
        results_in => 'dewey',
    },
    {
        datetime   => '2-Jan-99 23h59:00',
        results_in => 'dewey',
    },
    {
        epoch      => 915321540,
        results_in => 'dewey',
    },
    {
        datetime   => '1999-01-02 23:59:00',
        results_in => 'dewey',
    },
    {
        datetime   => '1999-01-02T23:59:00',
        results_in => 'dewey',
    },
    {
        datetime   => '19990102235900',
        results_in => 'dewey',
    },
    {
        datetime   => '1999-01-02T23:59:00Z',
        results_in => 'dewey',
    },
    {
        epoch      => 1310906096,
        results_in => 'louie',
    },
    {
        datetime   => '2011-07-17 12:34:56',
        results_in => 'louie',
    },
    {
        datetime   => 20110717123456,
        results_in => 'louie',
    },
    {
        datetime   => '2011-07-17T12:34:56Z',
        results_in => 'louie',
    },
);

my $date_obj;

foreach my $case (@testcases) {
    if ($case->{'datetime'}) {
        $date_obj = Date::Utility->new({datetime => $case->{'datetime'}});
    } else {
        $date_obj = Date::Utility->new({epoch => $case->{'epoch'}});
    }
    my $which = $case->{'results_in'};

    comparisons($date_obj, $which);
}

my $newstyle_testcases = {
    huey => [
        1278382486,
        '6-Jul-10 02:14:46GMT',
        '6-Jul-10 02:14:46',
        '2010-07-06 02:14:46',
        '2010-07-06T02:14:46',
        '2010-07-06T02:14:46Z',
        '20100706021446',
        '6-Jul-10 2h14:46',
        '6-Jul-10 2:14:46',
    ],
    dewey => [
        915321540,
        '2-Jan-99 23h59GMT',
        '2-Jan-99 23h59',
        '1999-01-02 23:59:00',
        '1999-01-02T23:59:00',
        '1999-01-02T23:59:00Z',
        '19990102235900',
        '2-Jan-99 23:59',
        '2-Jan-99 23h59:00'
    ],
    louie => [1310906096, '2011-07-17T12:34:56Z', '2011-07-17T12:34:56', '17-Jul-11 12:34:56', 20110717123456, '17-Jul-11 12:34:56GMT'],
};

foreach my $which (keys %{$newstyle_testcases}) {
    foreach my $time (@{$newstyle_testcases->{$which}}) {
        comparisons(Date::Utility->new($time), $which);
    }
}

sub comparisons {
    my ($date_obj, $which) = @_;

    isa_ok($date_obj, 'Date::Utility', 'Object creation for ' . $which);
    foreach my $attr (
        qw(epoch datetime datetime_ddmmmyy_hhmmss_TZ datetime_yyyymmdd_hhmmss datetime_iso8601 datetime_yyyymmdd_hhmmss_TZ date date_ddmmyy date_ddmmyyyy date_ddmmmyyyy date_ddmonthyyyy date_yyyymmdd day_as_string db_timestamp full_day_name is_a_weekday is_a_weekend iso8601 month_as_string full_month_name http_expires_format time time_hhmm time_hhmmss time_cutoff timezone quarter_of_year second minute hour day_of_month month year year_in_two_digit day_of_week day_of_year days_since_epoch seconds_after_midnight days_in_month is_dst_in_zone timezone_offset)
        )
    {
        if ($attr eq 'timezone_offset') {
            is($date_obj->$attr('America/New_York')->as_concise_string, $results{$which}->{$attr}, ' ' . $attr . ' matches.');
        } elsif ($attr eq 'is_dst_in_zone') {
            is($date_obj->$attr('America/New_York'), $results{$which}->{$attr}, ' ' . $attr . ' matches.');
        } else {
            is($date_obj->$attr, $results{$which}->{$attr}, ' ' . $attr . ' matches.');
        }

    }
}

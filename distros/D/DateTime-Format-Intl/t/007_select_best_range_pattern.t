#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $TEST_ID );
    use utf8;
    use version;
    use Test::More;
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;


my $tests = 
[
    # Note: test #0
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 16, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Bh",
        greatest_diff => "B",
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric" },
        pattern => "h B – h B",
    },
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 11, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Bh",
        greatest_diff => "h",
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric" },
        pattern => "h – h B",
    },
    {
        date1 => { day => 10, hour => 9, minute => 30, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 16, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "Bhm",
        greatest_diff => "B",
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", minute => "numeric" },
        pattern => "h:mm B – h:mm B",
    },
    {
        date1 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 11, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "Bhm",
        greatest_diff => "h",
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", minute => "numeric" },
        pattern => "h:mm – h:mm B",
    },
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "Bhm",
        greatest_diff => "m",
        locale => "en",
        options => { dayPeriod => "short", hour => "numeric", minute => "numeric" },
        pattern => "h:mm – h:mm B",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "d",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric" },
        pattern => "d – d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Gy",
        greatest_diff => "G",
        locale => "en",
        options => { era => "short", year => "numeric" },
        pattern => "y G – y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Gy",
        greatest_diff => "y",
        locale => "en",
        options => { era => "short", year => "numeric" },
        pattern => "y – y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        expects => "GyM",
        greatest_diff => "G",
        locale => "en",
        options => { era => "short", month => "numeric", year => "numeric" },
        pattern => "M/y G – M/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 7, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        expects => "GyM",
        greatest_diff => "M",
        locale => "en",
        options => { era => "short", month => "numeric", year => "numeric" },
        pattern => "M/y – M/y G",
    },
    # NOTE: test #10
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyM",
        greatest_diff => "y",
        locale => "en",
        options => { era => "short", month => "numeric", year => "numeric" },
        pattern => "M/y – M/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", era => "short", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMd",
        greatest_diff => "G",
        locale => "en",
        options => { day => "numeric", era => "short", month => "numeric", year => "numeric" },
        pattern => "M/d/y G – M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", era => "short", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", era => "short", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMEd",
        greatest_diff => "d",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, M/d/y – E, M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMEd",
        greatest_diff => "G",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, M/d/y G – E, M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMEd",
        greatest_diff => "M",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, M/d/y – E, M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMEd",
        greatest_diff => "y",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "numeric",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, M/d/y – E, M/d/y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        expects => "GyMMM",
        greatest_diff => "G",
        locale => "en",
        options => { era => "short", month => "short", year => "numeric" },
        pattern => "MMM y G – MMM y G",
    },
    # NOTE: test #20
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 7, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        expects => "GyMMM",
        greatest_diff => "M",
        locale => "en",
        options => { era => "short", month => "short", year => "numeric" },
        pattern => "MMM – MMM y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMM",
        greatest_diff => "y",
        locale => "en",
        options => { era => "short", month => "short", year => "numeric" },
        pattern => "MMM y – MMM y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", era => "short", month => "short", year => "numeric" },
        pattern => "MMM d – d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMd",
        greatest_diff => "G",
        locale => "en",
        options => { day => "numeric", era => "short", month => "short", year => "numeric" },
        pattern => "MMM d, y G – MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", era => "short", month => "short", year => "numeric" },
        pattern => "MMM d – MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", era => "short", month => "short", year => "numeric" },
        pattern => "MMM d, y – MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMEd",
        greatest_diff => "d",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, MMM d – E, MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => -2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMEd",
        greatest_diff => "G",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, MMM d, y G – E, MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMEd",
        greatest_diff => "M",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, MMM d – E, MMM d, y G",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "GyMMMEd",
        greatest_diff => "y",
        locale => "en",
        options => {
            day => "numeric",
            era => "short",
            month => "short",
            weekday => "short",
            year => "numeric",
        },
        pattern => "E, MMM d, y – E, MMM d, y G",
    },
    # NOTE: test #30
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 13, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "h",
        greatest_diff => "a",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12" },
        pattern => "h a – h a",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "h",
        greatest_diff => "h",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12" },
        pattern => "h – h a",
    },
    {
        date1 => { day => 10, hour => 13, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 14, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "H",
        greatest_diff => "H",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h24" },
        pattern => "HH – HH",
    },
    {
        date1 => { day => 10, hour => 9, minute => 30, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "hm",
        greatest_diff => "h",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12", minute => "numeric" },
        pattern => "h:mm a – h:mm a",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "hm",
        greatest_diff => "h",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12", minute => "numeric" },
        pattern => "h:mm – h:mm a",
    },
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "hm",
        greatest_diff => "m",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12", minute => "numeric" },
        pattern => "h:mm – h:mm a",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Hm",
        greatest_diff => "H",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h24", minute => "numeric" },
        pattern => "HH:mm – HH:mm",
    },
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "Hm",
        greatest_diff => "m",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h24", minute => "numeric" },
        pattern => "HH:mm – HH:mm",
    },
    {
        date1 => { day => 10, hour => 9, minute => 30, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "hmv",
        greatest_diff => "h",
        locale => "en",
        options => {
            hour => "numeric",
            hourCycle => "h12",
            minute => "numeric",
            timeZoneName => "short",
        },
        pattern => "h:mm a – h:mm a v",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "hmv",
        greatest_diff => "h",
        locale => "en",
        options => {
            hour => "numeric",
            hourCycle => "h12",
            minute => "numeric",
            timeZoneName => "short",
        },
        pattern => "h:mm – h:mm a v",
    },
    # NOTE: test #40
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "hmv",
        greatest_diff => "m",
        locale => "en",
        options => {
            hour => "numeric",
            hourCycle => "h12",
            minute => "numeric",
            timeZoneName => "short",
        },
        pattern => "h:mm – h:mm a v",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Hmv",
        greatest_diff => "H",
        locale => "en",
        options => {
            hour => "numeric",
            hourCycle => "h24",
            minute => "numeric",
            timeZoneName => "short",
        },
        pattern => "HH:mm – HH:mm v",
    },
    {
        date1 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "Hmv",
        greatest_diff => "m",
        locale => "en",
        options => {
            hour => "numeric",
            hourCycle => "h24",
            minute => "numeric",
            timeZoneName => "short",
        },
        pattern => "HH:mm – HH:mm v",
    },
    {
        date1 => { day => 10, hour => 9, minute => 30, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 30, month => 9, second => 0, year => 2024 },
        expects => "hv",
        greatest_diff => "h",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12", timeZoneName => "short" },
        pattern => "h a – h a v",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "hv",
        greatest_diff => "h",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h12", timeZoneName => "short" },
        pattern => "h – h a v",
    },
    {
        date1 => { day => 10, hour => 9, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 10, hour => 10, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Hv",
        greatest_diff => "H",
        locale => "en",
        options => { hour => "numeric", hourCycle => "h24", timeZoneName => "short" },
        pattern => "HH – HH v",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 6, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 7, second => 0, year => 2024 },
        expects => "M",
        greatest_diff => "M",
        locale => "en",
        options => { month => "numeric" },
        pattern => "M – M",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Md",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "numeric" },
        pattern => "M/d – M/d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "Md",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "numeric" },
        pattern => "M/d – M/d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MEd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short" },
        pattern => "E, M/d – E, M/d",
    },
    # NOTE: test #50
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MEd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short" },
        pattern => "E, M/d – E, M/d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 6, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 7, second => 0, year => 2024 },
        expects => "MMM",
        greatest_diff => "M",
        locale => "en",
        options => { month => "short" },
        pattern => "MMM – MMM",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MMMd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "short" },
        pattern => "MMM d – d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MMMd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "short" },
        pattern => "MMM d – MMM d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MMMEd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short" },
        pattern => "E, MMM d – E, MMM d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "MMMEd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short" },
        pattern => "E, MMM d – E, MMM d",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "y",
        greatest_diff => "y",
        locale => "en",
        options => { year => "numeric" },
        pattern => "y – y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 6, second => 0, year => 2024 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yM",
        greatest_diff => "M",
        locale => "en",
        options => { month => "numeric", year => "numeric" },
        pattern => "M/y – M/y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yM",
        greatest_diff => "y",
        locale => "en",
        options => { month => "numeric", year => "numeric" },
        pattern => "M/y – M/y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y",
    },
    # NOTE: test #60
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", month => "numeric", year => "numeric" },
        pattern => "M/d/y – M/d/y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMEd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short", year => "numeric" },
        pattern => "E, M/d/y – E, M/d/y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMEd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short", year => "numeric" },
        pattern => "E, M/d/y – E, M/d/y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMEd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", month => "numeric", weekday => "short", year => "numeric" },
        pattern => "E, M/d/y – E, M/d/y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 6, second => 0, year => 2024 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMM",
        greatest_diff => "M",
        locale => "en",
        options => { month => "short", year => "numeric" },
        pattern => "MMM – MMM y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMM",
        greatest_diff => "y",
        locale => "en",
        options => { month => "short", year => "numeric" },
        pattern => "MMM y – MMM y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "short", year => "numeric" },
        pattern => "MMM d – d, y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "short", year => "numeric" },
        pattern => "MMM d – MMM d, y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", month => "short", year => "numeric" },
        pattern => "MMM d, y – MMM d, y",
    },
    # NOTE: test #70
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        date2 => { day => 11, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMEd",
        greatest_diff => "d",
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short", year => "numeric" },
        pattern => "E, MMM d – E, MMM d, y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 8, second => 0, year => 2024 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMEd",
        greatest_diff => "M",
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short", year => "numeric" },
        pattern => "E, MMM d – E, MMM d, y",
    },
    {
        date1 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 10, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMEd",
        greatest_diff => "y",
        locale => "en",
        options => { day => "numeric", month => "short", weekday => "short", year => "numeric" },
        pattern => "E, MMM d, y – E, MMM d, y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 6, second => 0, year => 2024 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMM",
        greatest_diff => "M",
        locale => "en",
        options => { month => "long", year => "numeric" },
        pattern => "MMMM – MMMM y",
    },
    {
        date1 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2023 },
        date2 => { day => 1, hour => 0, minute => 0, month => 9, second => 0, year => 2024 },
        expects => "yMMMM",
        greatest_diff => "y",
        locale => "en",
        options => { month => "long", year => "numeric" },
        pattern => "MMMM y – MMMM y",
    },
];

my $failed = [];
for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    if( defined( $TEST_ID ) )
    {
        next unless( $i == $TEST_ID );
        last if( $i > $TEST_ID );
    }
    my $test = $tests->[$i];
    my @keys = sort( keys( %{$test->{options}} ) );
    local $" = ', ';
    subtest 'DateTime::Format::Intl->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{@keys\} )->_select_best_pattern( \$patterns, \{@keys\} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::Intl->new( $test->{locale}, $test->{options} );
        SKIP:
        {
            isa_ok( $fmt => 'DateTime::Format::Intl' );
            if( !defined( $fmt ) )
            {
                diag( "Error instantiating the DateTime::Format::Intl object: ", DateTime::Format::Intl->error );
                skip( "Unable to instantiate a new DateTime::Format::Intl object.", 1 );
            }
            my $dt1 = DateTime->new( %{$test->{date1}} );
            my $dt2 = DateTime->new( %{$test->{date2}} );
            my $date1 = $dt1->iso8601;
            my $date2 = $dt2->iso8601;
            my $str = $fmt->format_range( $dt1, $dt2 );
            # my $best_pattern = $fmt->_select_best_pattern( $patterns, $test->{options} );
            my $best_pattern = $fmt->interval_pattern;
            my $skeleton = $fmt->interval_skeleton;
            my $diff = $fmt->greatest_diff;
            if( !defined( $best_pattern ) )
            {
                diag( "Error getting the best skeleton: ", $fmt->error );
            }
            if( !is( $diff => $test->{greatest_diff}, "\$fmt->greatest_diff -> '" . ( $test->{greatest_diff} // 'undef' ) . "'" ) )
            {
                # push( @$failed, { test => $i, skeleton => $test->{expects}, diff => $test->{greatest_diff} } );
                push( @$failed, { test => $i, interval_pattern => $best_pattern, interval_skeleton => $skeleton, %$test } );
            }
            if( !is( $skeleton => $test->{expects}, "\$fmt->_select_best_pattern( \$patterns, \{@keys\} ) -> '$test->{expects}'" ) )
            {
                # push( @$failed, { test => $i, skeleton => $test->{expects}, diff => $test->{greatest_diff} } );
                push( @$failed, { test => $i, interval_pattern => $best_pattern, interval_skeleton => $skeleton, %$test } );
            }
        };
    };
}


done_testing();

__END__

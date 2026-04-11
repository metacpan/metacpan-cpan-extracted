#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/02.components.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

my $dt = DateTime::Lite->new(
    year      => 2025,
    month     => 4,
    day       => 3,
    hour      => 14,
    minute    => 30,
    second    => 45,
    time_zone => 'UTC',
);

# NOTE: Basic date/time components
is( $dt->year,        2025, 'year' );
is( $dt->month,       4,    'month' );
is( $dt->day,         3,    'day' );
is( $dt->hour,        14,   'hour' );
is( $dt->minute,      30,   'minute' );
is( $dt->second,      45,   'second' );
is( $dt->nanosecond,  0,    'nanosecond' );

# NOTE: Month variants
is( $dt->month_0, 3, 'month_0 (0-based)' );

# NOTE: Day-of-week (2025-04-03 is a Thursday = 4)
is( $dt->day_of_week,   4, 'day_of_week (Thursday=4)' );
is( $dt->day_of_week_0, 3, 'day_of_week_0 (0-based)' );

# NOTE: Day-of-year (April 3 = day 93 in non-leap year)
is( $dt->day_of_year, 93, 'day_of_year' );

# NOTE: Quarter (April = Q2)
is( $dt->quarter,   2, 'quarter' );
is( $dt->quarter_0, 1, 'quarter_0' );

# NOTE: Hour variants
is( $dt->hour_12,   2,  'hour_12 (14h -> 2)' );
is( $dt->hour_12_0, 2,  'hour_12_0' );
is( $dt->hour_1,    14, 'hour_1' );

# NOTE: String formats
is( $dt->ymd,      '2025-04-03',          'ymd()' );
is( $dt->ymd('/'), '2025/04/03',          'ymd("/")' );
is( $dt->mdy,      '04-03-2025',          'mdy()' );
is( $dt->dmy,      '03-04-2025',          'dmy()' );
is( $dt->hms,      '14:30:45',            'hms()' );
is( $dt->hms(''),  '143045',              'hms("")' );
is( $dt->datetime, '2025-04-03T14:30:45', 'datetime()' );
is( $dt->iso8601,  '2025-04-03T14:30:45', 'iso8601()' );

# NOTE: Epoch round-trip
subtest 'Epoch round-trip' => sub
{
    my $epoch = $dt->epoch;
    ok( defined( $epoch ), 'epoch() defined' );
    my $dt2 = DateTime::Lite->from_epoch( epoch => $epoch, time_zone => 'UTC' );
    is( $dt2->ymd,    $dt->ymd,    'epoch round-trip: ymd matches' );
    is( $dt2->hms,    $dt->hms,    'epoch round-trip: hms matches' );
};

# NOTE: is_last_day_of_month
subtest 'is_last_day_of_month' => sub
{
    ok( !$dt->is_last_day_of_month, 'April 3 is not the last day of month' );
    my $last = DateTime::Lite->new( year => 2025, month => 4, day => 30, time_zone => 'UTC' );
    ok( $last->is_last_day_of_month, 'April 30 is the last day of month' );
};

# NOTE: week / week_number / week_year
subtest 'week / week_number / week_year' => sub
{
    # 2025-04-03 is ISO week 14 of 2025
    my ( $wy, $wn ) = $dt->week;
    is( $wn, 14,   'week_number is 14' );
    is( $wy, 2025, 'week_year is 2025' );
    is( $dt->week_number,   14, 'week_number() accessor' );
    is( $dt->week_of_month,  1, 'week_of_month() for 2025-04-03' );
};

# NOTE: from_day_of_year
subtest 'from_day_of_year' => sub
{
    # Day 93 of 2025 should be April 3
    my $dt2 = DateTime::Lite->from_day_of_year(
        year        => 2025,
        day_of_year => 93,
        time_zone   => 'UTC',
    );
    ok( defined( $dt2 ), 'from_day_of_year() works' );
    is( $dt2->month, 4, 'from_day_of_year: month is April' );
    is( $dt2->day,   3, 'from_day_of_year: day is 3' );
};

# NOTE: Fractional second / millisecond / microsecond
subtest 'Fractional second / millisecond / microsecond' => sub
{
    my $dt3 = DateTime::Lite->new(
        year        => 2025,
        month       => 1,
        day         => 1,
        nanosecond  => 123_456_789,
        time_zone   => 'UTC',
    );
    is( $dt3->millisecond, 123,         'millisecond' );
    is( $dt3->microsecond, 123_456,     'microsecond' );
    ok( abs( $dt3->fractional_second - 0.123456789 ) < 1e-9,
        'fractional_second' );
};

# NOTE: rfc3339
subtest 'rfc3339' => sub
{
    my $s = $dt->rfc3339;
    like( $s, qr/2025-04-03T14:30:45/, 'rfc3339 contains datetime' );
    like( $s, qr/Z$/, 'rfc3339 ends in Z for UTC' );
};

done_testing;

__END__

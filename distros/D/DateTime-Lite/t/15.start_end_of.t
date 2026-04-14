#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/15.start_end_of.t
## Tests for start_of() and end_of() methods
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

my $dt = DateTime::Lite->new(
    year       => 2026,
    month      => 4,
    day        => 15,
    hour       => 14,
    minute     => 32,
    second     => 47,
    nanosecond => 123456789,
    time_zone  => 'UTC',
);
ok( defined( $dt ), 'base datetime created' );

# NOTE: start_of(second)
subtest 'start_of(second)' => sub
{
    my $r = $dt->clone->start_of( 'second' );
    ok( defined( $r ), 'start_of(second) succeeds' );
    is( $r->nanosecond, 0,  'nanosecond = 0' );
    is( $r->second,     47, 'second unchanged' );
    is( $r->minute,     32, 'minute unchanged' );
};

# NOTE: start_of(minute)
subtest 'start_of(minute)' => sub
{
    my $r = $dt->clone->start_of( 'minute' );
    ok( defined( $r ), 'start_of(minute) succeeds' );
    is( $r->second,     0,  'second = 0' );
    is( $r->nanosecond, 0,  'nanosecond = 0' );
    is( $r->minute,     32, 'minute unchanged' );
    is( $r->hour,       14, 'hour unchanged' );
};

# NOTE: start_of(hour)
subtest 'start_of(hour)' => sub
{
    my $r = $dt->clone->start_of( 'hour' );
    ok( defined( $r ), 'start_of(hour) succeeds' );
    is( $r->minute,     0,  'minute = 0' );
    is( $r->second,     0,  'second = 0' );
    is( $r->nanosecond, 0,  'nanosecond = 0' );
    is( $r->hour,       14, 'hour unchanged' );
};

# NOTE: start_of(day)
subtest 'start_of(day)' => sub
{
    my $r = $dt->clone->start_of( 'day' );
    ok( defined( $r ), 'start_of(day) succeeds' );
    is( $r->hour,       0,  'hour = 0' );
    is( $r->minute,     0,  'minute = 0' );
    is( $r->second,     0,  'second = 0' );
    is( $r->nanosecond, 0,  'nanosecond = 0' );
    is( $r->day,        15, 'day unchanged' );
};

# NOTE: start_of(month)
subtest 'start_of(month)' => sub
{
    my $r = $dt->clone->start_of( 'month' );
    ok( defined( $r ), 'start_of(month) succeeds' );
    is( $r->day,        1,  'day = 1' );
    is( $r->hour,       0,  'hour = 0' );
    is( $r->month,      4,  'month unchanged' );
    is( $r->year,       2026, 'year unchanged' );
};

# NOTE: start_of(quarter)
subtest 'start_of(quarter)' => sub
{
    my $r = $dt->clone->start_of( 'quarter' );
    ok( defined( $r ), 'start_of(quarter) succeeds' );
    is( $r->month, 4, 'Q2 starts in April' );
    is( $r->day,   1, 'day = 1' );
    is( $r->hour,  0, 'hour = 0' );

    # Q1 check
    my $q1 = DateTime::Lite->new(
        year      => 2026,
        month     => 2,
        day       => 14,
        time_zone => 'UTC'
    )->start_of( 'quarter' );
    is( $q1->month, 1, 'Q1 starts in January' );
};

# NOTE: start_of(year)
subtest 'start_of(year)' => sub
{
    my $r = $dt->clone->start_of( 'year' );
    ok( defined( $r ), 'start_of(year) succeeds' );
    is( $r->month,  1,    'month = 1' );
    is( $r->day,    1,    'day = 1' );
    is( $r->hour,   0,    'hour = 0' );
    is( $r->year,   2026, 'year unchanged' );
};

# NOTE: start_of(decade)
subtest 'start_of(decade)' => sub
{
    my $r = $dt->clone->start_of( 'decade' );
    ok( defined( $r ), 'start_of(decade) succeeds' );
    is( $r->year,  2020, 'decade starts at 2020' );
    is( $r->month, 1,    'month = 1' );
    is( $r->day,   1,    'day = 1' );
};

# NOTE: start_of(century)
subtest 'start_of(century)' => sub
{
    my $r = $dt->clone->start_of( 'century' );
    ok( defined( $r ), 'start_of(century) succeeds' );
    is( $r->year,  2001, 'century starts at 2001' );
    is( $r->month, 1,    'month = 1' );
    is( $r->day,   1,    'day = 1' );
};

# NOTE: end_of(second)
subtest 'end_of(second)' => sub
{
    my $r = $dt->clone->end_of( 'second' );
    ok( defined( $r ), 'end_of(second) succeeds' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->second,     47,          'second unchanged' );
    is( $r->minute,     32,          'minute unchanged' );
};

# NOTE: end_of(minute)
subtest 'end_of(minute)' => sub
{
    my $r = $dt->clone->end_of( 'minute' );
    ok( defined( $r ), 'end_of(minute) succeeds' );
    is( $r->second,     59,          'second = 59' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->minute,     32,          'minute unchanged' );
};

# NOTE: end_of(hour)
subtest 'end_of(hour)' => sub
{
    my $r = $dt->clone->end_of( 'hour' );
    ok( defined( $r ), 'end_of(hour) succeeds' );
    is( $r->minute,     59,          'minute = 59' );
    is( $r->second,     59,          'second = 59' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->hour,       14,          'hour unchanged' );
};

# NOTE: end_of(day)
subtest 'end_of(day)' => sub
{
    my $r = $dt->clone->end_of( 'day' );
    ok( defined( $r ), 'end_of(day) succeeds' );
    is( $r->hour,       23,          'hour = 23' );
    is( $r->minute,     59,          'minute = 59' );
    is( $r->second,     59,          'second = 59' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->day,        15,          'day unchanged' );
};

# NOTE: end_of(month)
subtest 'end_of(month)' => sub
{
    my $r = $dt->clone->end_of( 'month' );
    ok( defined( $r ), 'end_of(month) succeeds' );
    is( $r->day,        30,          'April ends on day 30' );
    is( $r->hour,       23,          'hour = 23' );
    is( $r->minute,     59,          'minute = 59' );
    is( $r->second,     59,          'second = 59' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->month,      4,           'month unchanged' );

    # February in a leap year
    my $feb = DateTime::Lite->new(
        year      => 2024,
        month     => 2,
        day       => 10,
        time_zone => 'UTC'
    )->end_of( 'month' );
    is( $feb->day, 29, 'February 2024 (leap year) ends on day 29' );

    # February in a non-leap year
    my $feb2 = DateTime::Lite->new(
        year      => 2026,
        month     => 2,
        day       => 10,
        time_zone => 'UTC'
    )->end_of( 'month' );
    is( $feb2->day, 28, 'February 2026 (non-leap year) ends on day 28' );
};

# NOTE: end_of(quarter)
subtest 'end_of(quarter)' => sub
{
    my $r = $dt->clone->end_of( 'quarter' );
    ok( defined( $r ), 'end_of(quarter) succeeds' );
    is( $r->month,      6,           'Q2 ends in June' );
    is( $r->day,        30,          'June ends on day 30' );
    is( $r->hour,       23,          'hour = 23' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
};

# NOTE: end_of(year)
subtest 'end_of(year)' => sub
{
    my $r = $dt->clone->end_of( 'year' );
    ok( defined( $r ), 'end_of(year) succeeds' );
    is( $r->month,      12,          'month = 12' );
    is( $r->day,        31,          'day = 31' );
    is( $r->hour,       23,          'hour = 23' );
    is( $r->minute,     59,          'minute = 59' );
    is( $r->second,     59,          'second = 59' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
    is( $r->year,       2026,        'year unchanged' );
};

# NOTE: end_of(decade)
subtest 'end_of(decade)' => sub
{
    my $r = $dt->clone->end_of( 'decade' );
    ok( defined( $r ), 'end_of(decade) succeeds' );
    is( $r->year,       2029,        'decade ends at 2029' );
    is( $r->month,      12,          'month = 12' );
    is( $r->day,        31,          'day = 31' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
};

# NOTE: end_of(century)
subtest 'end_of(century)' => sub
{
    my $r = $dt->clone->end_of( 'century' );
    ok( defined( $r ), 'end_of(century) succeeds' );
    is( $r->year,       2100,        'century ends at 2100' );
    is( $r->month,      12,          'month = 12' );
    is( $r->day,        31,          'day = 31' );
    is( $r->nanosecond, 999_999_999, 'nanosecond = 999_999_999' );
};

# NOTE: start_of / end_of preserve timezone and locale
subtest 'start_of / end_of preserve timezone and locale' => sub
{
    my $dt_tz = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 15,
        hour      => 14,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP',
    );
    my $s = $dt_tz->clone->start_of( 'month' );
    is( $s->time_zone_long_name, 'Asia/Tokyo', 'start_of preserves timezone' );
    is( $s->locale->language_code, 'ja', 'start_of preserves locale' );

    my $e = $dt_tz->clone->end_of( 'month' );
    is( $e->time_zone_long_name, 'Asia/Tokyo', 'end_of preserves timezone' );
};

# NOTE: invalid unit returns error, not die
subtest 'Invalid unit returns error gracefully' => sub
{
    local $SIG{__WARN__} = sub {};
    my $r = $dt->clone->start_of( 'fortnight' );
    ok( !defined( $r ), 'start_of(fortnight) returns undef' );
    ok( defined( DateTime::Lite->error ), 'error is set' );

    my $r2 = $dt->clone->end_of( 'millennium' );
    ok( !defined( $r2 ), 'end_of(millennium) returns undef' );
};

done_testing;

__END__

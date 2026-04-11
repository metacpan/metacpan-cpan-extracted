#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/01.sanity.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

# To generate this list:
# perl -lnE '/^sub\s+(?!new|[A-Z]|_)([a-z]\w*)\b(?!.*;)/ and $seen{$1}++; END { say "can_ok( \$dt, \''$_\'' );" for sort( keys( %seen ) ) }' ./lib/DateTime/Lite.pm
# NOTE: methods check
subtest 'methods check' => sub
{
    my $dt = DateTime::Lite->now;
    isa_ok( $dt, 'DateTime::Lite' );
    can_ok( $dt, 'add_duration' );
    can_ok( $dt, 'am_or_pm' );
    can_ok( $dt, 'ce_year' );
    can_ok( $dt, 'christian_era' );
    can_ok( $dt, 'compare_ignore_floating' );
    can_ok( $dt, 'datetime' );
    can_ok( $dt, 'day' );
    can_ok( $dt, 'day_abbr' );
    can_ok( $dt, 'day_name' );
    can_ok( $dt, 'day_of_month_0' );
    can_ok( $dt, 'day_of_quarter' );
    can_ok( $dt, 'day_of_quarter_0' );
    can_ok( $dt, 'day_of_week_0' );
    can_ok( $dt, 'day_of_year_0' );
    can_ok( $dt, 'delta_days' );
    can_ok( $dt, 'delta_md' );
    can_ok( $dt, 'delta_ms' );
    can_ok( $dt, 'dmy' );
    can_ok( $dt, 'duration_class' );
    can_ok( $dt, 'epoch' );
    can_ok( $dt, 'era_abbr' );
    can_ok( $dt, 'era_name' );
    can_ok( $dt, 'error' );
    can_ok( $dt, 'fractional_second' );
    can_ok( $dt, 'from_day_of_year' );
    can_ok( $dt, 'from_epoch' );
    can_ok( $dt, 'from_object' );
    can_ok( $dt, 'hires_epoch' );
    can_ok( $dt, 'hms' );
    can_ok( $dt, 'hour_1' );
    can_ok( $dt, 'hour_12' );
    can_ok( $dt, 'hour_12_0' );
    can_ok( $dt, 'is_between' );
    can_ok( $dt, 'is_dst' );
    can_ok( $dt, 'is_finite' );
    can_ok( $dt, 'is_infinite' );
    can_ok( $dt, 'is_last_day_of_month' );
    can_ok( $dt, 'is_last_day_of_quarter' );
    can_ok( $dt, 'is_last_day_of_year' );
    can_ok( $dt, 'is_leap_year' );
    can_ok( $dt, 'iso8601' );
    can_ok( $dt, 'jd' );
    can_ok( $dt, 'last_day_of_month' );
    can_ok( $dt, 'leap_seconds' );
    can_ok( $dt, 'local_day_of_week' );
    can_ok( $dt, 'local_rd_as_seconds' );
    can_ok( $dt, 'local_rd_values' );
    can_ok( $dt, 'locale' );
    can_ok( $dt, 'mdy' );
    can_ok( $dt, 'microsecond' );
    can_ok( $dt, 'millisecond' );
    can_ok( $dt, 'minute' );
    can_ok( $dt, 'mjd' );
    can_ok( $dt, 'month' );
    can_ok( $dt, 'month_0' );
    can_ok( $dt, 'month_abbr' );
    can_ok( $dt, 'month_length' );
    can_ok( $dt, 'month_name' );
    can_ok( $dt, 'nanosecond' );
    can_ok( $dt, 'now' );
    can_ok( $dt, 'offset' );
    can_ok( $dt, 'pass_error' );
    can_ok( $dt, 'quarter' );
    can_ok( $dt, 'quarter_0' );
    can_ok( $dt, 'quarter_abbr' );
    can_ok( $dt, 'quarter_length' );
    can_ok( $dt, 'quarter_name' );
    can_ok( $dt, 'rfc3339' );
    can_ok( $dt, 'second' );
    can_ok( $dt, 'secular_era' );
    can_ok( $dt, 'set' );
    can_ok( $dt, 'set_formatter' );
    can_ok( $dt, 'set_locale' );
    can_ok( $dt, 'set_time_zone' );
    can_ok( $dt, 'set_year' );
    can_ok( $dt, 'stringify' );
    can_ok( $dt, 'subtract' );
    can_ok( $dt, 'subtract_datetime' );
    can_ok( $dt, 'subtract_datetime_absolute' );
    can_ok( $dt, 'subtract_duration' );
    can_ok( $dt, 'time_zone' );
    can_ok( $dt, 'time_zone_long_name' );
    can_ok( $dt, 'time_zone_short_name' );
    can_ok( $dt, 'today' );
    can_ok( $dt, 'truncate' );
    can_ok( $dt, 'utc_rd_as_seconds' );
    can_ok( $dt, 'utc_rd_values' );
    can_ok( $dt, 'utc_year' );
    can_ok( $dt, 'week' );
    can_ok( $dt, 'week_number' );
    can_ok( $dt, 'week_of_month' );
    can_ok( $dt, 'week_year' );
    can_ok( $dt, 'weekday_of_month' );
    can_ok( $dt, 'year' );
    can_ok( $dt, 'year_length' );
    can_ok( $dt, 'year_with_christian_era' );
    can_ok( $dt, 'year_with_era' );
    can_ok( $dt, 'year_with_secular_era' );
    can_ok( $dt, 'ymd' );
};

# NOTE: Basic constructor
subtest 'Basic constructor' => sub
{
    my $dt = DateTime::Lite->new(
        year   => 2025,
        month  => 4,
        day    => 3,
        hour   => 9,
        minute => 30,
        second => 15,
    );
    ok( defined( $dt ), 'new() returns an object' );
    isa_ok( $dt, 'DateTime::Lite' );

    is( $dt->year,   2025, 'year()' );
    is( $dt->month,  4,    'month()' );
    is( $dt->day,    3,    'day()' );
    is( $dt->hour,   9,    'hour()' );
    is( $dt->minute, 30,   'minute()' );
    is( $dt->second, 15,   'second()' );

    is( $dt->nanosecond, 0, 'nanosecond() defaults to 0' );
    ok( $dt->is_finite,   'is_finite() is true' );
    ok( !$dt->is_infinite, 'is_infinite() is false' );
};

# NOTE: Default month/day
subtest 'Default month/day' => sub
{
    my $dt = DateTime::Lite->new( year => 2025 );
    ok( defined( $dt ), 'new() with year only' );
    is( $dt->month, 1, 'month defaults to 1' );
    is( $dt->day,   1, 'day defaults to 1' );
    is( $dt->hour,  0, 'hour defaults to 0' );
};

# NOTE: UTC timezone constructor
subtest 'UTC timezone constructor' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 1,
        day       => 1,
        time_zone => 'UTC',
    );
    ok( defined( $dt ), 'new() with UTC time zone' );
    is( $dt->time_zone->name, 'UTC', 'time_zone name is UTC' );
    is( $dt->offset, 0, 'UTC offset is 0' );
};

# NOTE: Leap year
subtest 'Leap year' => sub
{
    ok( DateTime::Lite->new( year => 2000 )->is_leap_year, '2000 is a leap year' );
    ok( DateTime::Lite->new( year => 2024 )->is_leap_year, '2024 is a leap year' );
    ok( !DateTime::Lite->new( year => 1900 )->is_leap_year, '1900 is not a leap year' );
    ok( !DateTime::Lite->new( year => 2025 )->is_leap_year, '2025 is not a leap year' );
};

# NOTE: Last day of month
subtest 'Last day of month' => sub
{
    my $dt = DateTime::Lite->last_day_of_month( year => 2025, month => 2 );
    ok( defined( $dt ), 'last_day_of_month() works' );
    is( $dt->day, 28, 'last day of Feb 2025 is 28' );

    my $dt2 = DateTime::Lite->last_day_of_month( year => 2024, month => 2 );
    is( $dt2->day, 29, 'last day of Feb 2024 is 29 (leap year)' );

    my $dt3 = DateTime::Lite->last_day_of_month( year => 2025, month => 1 );
    is( $dt3->day, 31, 'last day of Jan is 31' );
};

# NOTE: from_epoch
subtest 'from_epoch' => sub
{
    # Unix epoch 0 = 1970-01-01T00:00:00 UTC
    my $dt = DateTime::Lite->from_epoch( epoch => 0, time_zone => 'UTC' );
    ok( defined( $dt ), 'from_epoch( 0 ) works' );
    is( $dt->year,   1970, 'epoch 0: year is 1970' );
    is( $dt->month,  1,    'epoch 0: month is 1' );
    is( $dt->day,    1,    'epoch 0: day is 1' );
    is( $dt->hour,   0,    'epoch 0: hour is 0' );
    is( $dt->minute, 0,    'epoch 0: minute is 0' );
    is( $dt->second, 0,    'epoch 0: second is 0' );
    is( $dt->epoch,  0,    'epoch() round-trips to 0' );
};

# NOTE: from_epoch with float
subtest 'from_epoch with float' => sub
{
    my $dt = DateTime::Lite->from_epoch( epoch => 0.5, time_zone => 'UTC' );
    ok( defined( $dt ), 'from_epoch( 0.5 ) works' );
    is( $dt->second, 0, 'from_epoch(0.5): second is 0' );
    ok( $dt->nanosecond > 0, 'from_epoch(0.5): nanosecond is positive' );
};

# NOTE: now() - just check it returns something sensible
subtest 'now() - just check it returns something sensible' => sub
{
    my $dt = DateTime::Lite->now( time_zone => 'UTC' );
    ok( defined( $dt ), 'now() returns an object' );
    ok( $dt->year >= 2025, 'now() year is sane' );
};

# NOTE: clone (XS deep copy)
subtest 'clone' => sub
{
    my $dt1 = DateTime::Lite->new(
        year      => 2025,
        month     => 6,
        day       => 15,
        hour      => 12,
        minute    => 30,
        second    => 45,
        time_zone => 'UTC',
    );
    my $dt2 = $dt1->clone;

    # Values are preserved
    is( $dt2->year,   2025,  'clone: year'   );
    is( $dt2->month,  6,     'clone: month'  );
    is( $dt2->day,    15,    'clone: day'    );
    is( $dt2->hour,   12,    'clone: hour'   );
    is( $dt2->minute, 30,    'clone: minute' );
    is( $dt2->second, 45,    'clone: second' );
    is( $dt2->epoch,  $dt1->epoch, 'clone: epoch matches' );
    is( ref( $dt2 ), 'DateTime::Lite', 'clone: correct class' );

    # The clone is a distinct object
    isnt( Scalar::Util::refaddr( $dt1 ), Scalar::Util::refaddr( $dt2 ),
        'clone: different root object' );

    # Nested objects are independent copies (XS deep copy)
    isnt( Scalar::Util::refaddr( $dt1->{tz} ),
          Scalar::Util::refaddr( $dt2->{tz} ),
          'clone: tz is a deep copy' );
    isnt( Scalar::Util::refaddr( $dt1->{locale} ),
          Scalar::Util::refaddr( $dt2->{locale} ),
          'clone: locale is a deep copy' );

    # Mutating the clone does not affect the original
    if( !defined( $dt2->set_time_zone( 'Asia/Tokyo' ) ) )
    {
        diag( "Error setting time zone: ", $dt2->error );
    }
    is( $dt1->time_zone->name, 'UTC',        'clone: original tz unchanged' );
    is( $dt2->time_zone->name, 'Asia/Tokyo', 'clone: cloned tz changed'     );

    # Direct mutation of nested locale does not bleed through
    my $dt3 = $dt1->clone;
    $dt3->{locale}->{locale} = 'fr-FR';
    isnt( $dt1->{locale}->{locale}, 'fr-FR', 'clone: locale mutation isolated' );
};

# NOTE: Error handling: missing year
subtest 'Error handling: missing year' => sub
{
    # error() emits a warning by design; suppress it to keep TAP clean.
    my $dt;
    {
        local $SIG{__WARN__} = sub{};
        $dt = DateTime::Lite->new( month => 3 );
    }
    ok( !defined( $dt ), 'new() without year returns undef' );
    my $err = DateTime::Lite->error;
    ok( defined( $err ), 'error() is set after failed new()' );
    like( "$err", qr/year/i, 'error message mentions year' );
};

# NOTE: Error handling: invalid day
subtest 'Error handling: invalid day' => sub
{
    my $dt;
    {
        local $SIG{__WARN__} = sub{};
        $dt = DateTime::Lite->new( year => 2025, month => 2, day => 30 );
    }
    ok( !defined( $dt ), 'new() with Feb 30 returns undef' );
    ok( defined( DateTime::Lite->error ), 'error() is set for invalid day' );
};

done_testing;

__END__

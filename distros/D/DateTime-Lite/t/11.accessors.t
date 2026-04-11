#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/11.accessors.t
## Covers public accessors not exercised by the other test files.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

# Reference date: 2026-04-03T14:30:45.123456789 UTC
# Friday, day 93 of year, Q2, week 14
my $dt = DateTime::Lite->new(
    year       => 2026,
    month      => 4,
    day        => 3,
    hour       => 14,
    minute     => 30,
    second     => 45,
    nanosecond => 123_456_789,
    time_zone  => 'UTC',
);
ok( defined( $dt ), 'reference DT created' );

# NOTE: Basic date/time components
subtest 'Basic date/time components' => sub
{
    is( $dt->year,    2026, 'year()' );
    is( $dt->month,   4,    'month()' );
    is( $dt->day,     3,    'day()' );
    is( $dt->hour,    14,   'hour()' );
    is( $dt->minute,  30,   'minute()' );
    is( $dt->second,  45,   'second()' );
    is( $dt->nanosecond, 123_456_789, 'nanosecond()' );

    is( $dt->month_0,        3, 'month_0()' );
    is( $dt->day_of_month_0, 2, 'day_of_month_0()' );
};

# NOTE: Day-of-week (2026-04-03 is Friday = 5)
is( $dt->day_of_week,   5, 'day_of_week() Friday=5' );
is( $dt->day_of_week_0, 4, 'day_of_week_0()' );

# NOTE: Day-of-year (April 3 = day 93 in non-leap 2026)
is( $dt->day_of_year,   93, 'day_of_year()' );
is( $dt->day_of_year_0, 92, 'day_of_year_0()' );

# NOTE: Quarter (April = Q2)
subtest 'Quarter' => sub
{
    is( $dt->quarter,          2, 'quarter()' );
    is( $dt->quarter_0,        1, 'quarter_0()' );
    is( $dt->day_of_quarter,   3, 'day_of_quarter()' );
    is( $dt->day_of_quarter_0, 2, 'day_of_quarter_0()' );

    my $q_len = $dt->quarter_length;
    ok( $q_len == 91 || $q_len == 92, 'quarter_length() 91 or 92' );

    my $qn = $dt->quarter_name;
    ok( defined( $qn ) && length( $qn ), 'quarter_name() non-empty' );
    my $qa = $dt->quarter_abbr;
    ok( defined( $qa ) && length( $qa ), 'quarter_abbr() non-empty' );
};

# NOTE: Hour variants
subtest 'Hour variants' => sub
{
    is( $dt->hour_12,    2, 'hour_12() 14h -> 2' );
    is( $dt->hour_12_0,  2, 'hour_12_0()' );
    is( $dt->hour_1,    14, 'hour_1() non-midnight' );

    my $dt_mid = DateTime::Lite->new(
        year      => 2026,
        month     => 1,
        day       => 1,
        hour      => 0,
        time_zone => 'UTC'
    );
    is( $dt_mid->hour_12,   12, 'hour_12() midnight=12' );
    is( $dt_mid->hour_12_0,  0, 'hour_12_0() midnight=0' );
    is( $dt_mid->hour_1,    24, 'hour_1() midnight=24' );

    # NOTE: AM/PM
    is( $dt->am_or_pm,     'PM', 'am_or_pm() afternoon' );
    is( $dt_mid->am_or_pm, 'AM', 'am_or_pm() midnight' );
    is( DateTime::Lite->new( year => 2026, month => 6, day => 15, hour => 12, time_zone => 'UTC' )
                  ->am_or_pm, 'PM', 'am_or_pm() noon is PM' );
};

# Sub-second
ok( abs( $dt->fractional_second - 45.123456789 ) < 1e-9, 'fractional_second()' );
is( $dt->millisecond, 123,     'millisecond()' );
is( $dt->microsecond, 123_456, 'microsecond()' );

# NOTE: Epoch and Julian
my $epoch = $dt->epoch;
ok( $epoch > 0, 'epoch() positive' );

my $hires = $dt->hires_epoch;
ok( abs( $hires - ( $epoch + 0.123456789 ) ) < 1e-6, 'hires_epoch()' );

my $mjd = $dt->mjd;
ok( $mjd > 50000, 'mjd() plausible' );
ok( abs( $dt->jd - ( $mjd + 2_400_000.5 ) ) < 0.001, 'jd() = mjd + 2400000.5' );

# NOTE: Week
is( $dt->week_number,     14, 'week_number()' );
is( $dt->week_year,     2026, 'week_year()' );
ok( $dt->week_of_month >= 1 && $dt->week_of_month <= 5, 'week_of_month()' );
is( $dt->weekday_of_month, 1, 'weekday_of_month() first Friday of April' );

# NOTE: Month/year lengths and predicates
is( $dt->month_length, 30,  'month_length() April=30' );
is( $dt->year_length,  365, 'year_length() non-leap 2026' );
is( DateTime::Lite->new( year => 2024, month => 1, day => 1, time_zone => 'UTC' )
              ->year_length, 366, 'year_length() leap 2024' );

ok( !$dt->is_last_day_of_month, 'is_last_day_of_month() April 3 is not' );
ok( DateTime::Lite->new( year => 2026, month => 4, day => 30, time_zone => 'UTC' )
              ->is_last_day_of_month, 'is_last_day_of_month() April 30 is' );
ok( !$dt->is_last_day_of_quarter, 'is_last_day_of_quarter() April 3 is not' );
ok( DateTime::Lite->new( year => 2026, month => 6, day => 30, time_zone => 'UTC' )
              ->is_last_day_of_quarter, 'is_last_day_of_quarter() June 30 is' );
ok( !$dt->is_last_day_of_year, 'is_last_day_of_year() April 3 is not' );
ok( DateTime::Lite->new( year => 2026, month => 12, day => 31, time_zone => 'UTC' )
              ->is_last_day_of_year, 'is_last_day_of_year() Dec 31 is' );
ok( !$dt->is_leap_year, 'is_leap_year() 2026 not leap' );
ok( DateTime::Lite->new( year => 2024, month => 1, day => 1, time_zone => 'UTC' )
              ->is_leap_year, 'is_leap_year() 2024 is leap' );

# NOTE: Era and year variants
subtest 'era' => sub
{
    is( $dt->ce_year,        2026, 'ce_year() AD' );
    is( $dt->christian_era,  'AD', 'christian_era()' );
    is( $dt->secular_era,    'CE', 'secular_era()' );
    like( $dt->year_with_era,            qr/2026/, 'year_with_era()' );
    like( $dt->year_with_christian_era,  qr/2026/, 'year_with_christian_era()' );
    like( $dt->year_with_secular_era,    qr/2026/, 'year_with_secular_era()' );
};

my $dt_bc = DateTime::Lite->new( year => -100, month => 6, day => 15, time_zone => 'UTC' );
is( $dt_bc->ce_year,       -101,  'ce_year() BC is year-1' );
is( $dt_bc->christian_era, 'BC',  'christian_era() BC' );
is( $dt_bc->secular_era,   'BCE', 'secular_era() BCE' );

ok( defined( $dt->era_abbr ), 'era_abbr() defined' );
ok( defined( $dt->era_name ), 'era_name() defined' );

# NOTE: Locale-dependent name accessors
ok( defined( $dt->month_name ) && length( $dt->month_name ), 'month_name() non-empty' );
ok( defined( $dt->month_abbr ) && length( $dt->month_abbr ), 'month_abbr() non-empty' );
ok( defined( $dt->day_name )   && length( $dt->day_name ),   'day_name() non-empty' );
ok( defined( $dt->day_abbr )   && length( $dt->day_abbr ),   'day_abbr() non-empty' );

# NOTE: Formatting
is( $dt->datetime,      '2026-04-03T14:30:45', 'datetime()' );
is( $dt->datetime(' '), '2026-04-03 14:30:45', 'datetime(" ")' );
is( $dt->iso8601,       '2026-04-03T14:30:45', 'iso8601()' );
is( $dt->stringify,     '2026-04-03T14:30:45', 'stringify()' );
is( "$dt",              '2026-04-03T14:30:45', 'overloaded ""' );
is( $dt->ymd,           '2026-04-03',          'ymd()' );
is( $dt->ymd('/'),      '2026/04/03',          'ymd("/")' );
is( $dt->hms,           '14:30:45',            'hms()' );
is( $dt->hms(''),       '143045',              'hms("")' );
is( $dt->dmy,           '03-04-2026',          'dmy()' );
is( $dt->dmy('/'),      '03/04/2026',          'dmy("/")' );
is( $dt->mdy,           '04-03-2026',          'mdy()' );
is( $dt->mdy('/'),      '04/03/2026',          'mdy("/")' );

# NOTE: UTC / RD internals
my @utc = $dt->utc_rd_values;
is( scalar( @utc ), 3,      'utc_rd_values() 3 elements' );
ok( $utc[0] > 700000,       'utc_rd_values()[0] days plausible' );

my @loc = $dt->local_rd_values;
is( $loc[0], $utc[0],       'local_rd_values()[0] == utc for UTC tz' );

my $utc_secs = $dt->utc_rd_as_seconds;
ok( $utc_secs > 0,          'utc_rd_as_seconds() positive' );
is( $dt->local_rd_as_seconds, $utc_secs, 'local_rd_as_seconds() == utc for UTC tz' );

# utc_year is year + 1 (internal bootstrap value used by DateTime)
is( $dt->utc_year, 2027,    'utc_year()' );

# NOTE: Timezone accessors
subtest 'Timezone accessors' => sub
{
    is( $dt->time_zone->name,     'UTC', 'time_zone()->name' );
    is( $dt->time_zone_long_name, 'UTC', 'time_zone_long_name()' );
    ok( defined( $dt->time_zone_short_name ), 'time_zone_short_name()' );
    is( $dt->offset, 0,           'offset() for UTC' );
    is( $dt->is_dst, 0,           'is_dst() for UTC' );
    is( $dt->leap_seconds, 27,    'leap_seconds() UTC=27 (accumulated since 1972)' );

    my $dt_tok = DateTime::Lite->new(
        year => 2026, month => 7, day => 4, hour => 12, time_zone => 'Asia/Tokyo'
    );
    is( $dt_tok->offset, 32400, 'offset() Tokyo=+9h' );
    is( $dt_tok->is_dst,     0, 'is_dst() Tokyo no DST' );
    is( $dt_tok->time_zone_long_name,  'Asia/Tokyo', 'time_zone_long_name() Tokyo' );
    is( $dt_tok->time_zone_short_name, 'JST',        'time_zone_short_name() Tokyo' );
};

# NOTE: Locale and formatter
ok( defined( $dt->locale ),     'locale() defined' );
ok( !defined( $dt->formatter ), 'formatter() undef by default' );

my $fmt = bless {}, 'TestFmt';
{ no strict 'refs'; *{'TestFmt::format_datetime'} = sub { 'FORMATTED' } }
my $dt2 = $dt->clone;
$dt2->set_formatter( $fmt );
is( $dt2->formatter, $fmt,         'formatter() after set_formatter()' );
is( "$dt2",          'FORMATTED',  'overloaded "" uses formatter' );

# NOTE: duration_class, is_finite, is_infinite
is( DateTime::Lite->duration_class, 'DateTime::Lite::Duration', 'duration_class()' );
is( $dt->is_finite,   1, 'is_finite() true for normal object' );
is( $dt->is_infinite, 0, 'is_infinite() false for normal object' );

# NOTE: from_object
subtest 'from_object' => sub
{
    my $src = DateTime::Lite->new(
        year => 2026, month => 6, day => 15, hour => 10, time_zone => 'UTC'
    );
    my $dst = DateTime::Lite->from_object( object => $src );
    ok( defined( $dst ), 'from_object() succeeds' );
    is( $dst->epoch, $src->epoch, 'from_object() epoch preserved' );

    my $dst_tok = DateTime::Lite->from_object(
        object => $src, time_zone => 'Asia/Tokyo'
    );
    is( $dst_tok->hour,  19, 'from_object() with time_zone: hour shifted' );
    is( $dst_tok->epoch, $src->epoch, 'from_object() epoch unchanged' );
};

# NOTE: today
subtest 'today' => sub
{
    my $today = DateTime::Lite->today( time_zone => 'UTC' );
    ok( defined( $today ), 'today() defined' );
    is( $today->hour,   0, 'today() hour=0' );
    is( $today->minute, 0, 'today() minute=0' );
    is( $today->second, 0, 'today() second=0' );
};

# NOTE: local_day_of_week
subtest 'local_day_of_week' => sub
{
    my $ldow = $dt->local_day_of_week;
    ok( $ldow >= 1 && $ldow <= 7, 'local_day_of_week() in 1..7' );
};

# NOTE: delta_md / delta_ms
subtest 'delta_md / delta_ms' => sub
{
    my $dt_a = DateTime::Lite->new( year => 2026, month => 1, day => 1, time_zone => 'UTC' );
    my $dt_b = DateTime::Lite->new( year => 2026, month => 4, day => 1, time_zone => 'UTC' );
    my $md = $dt_a->delta_md( $dt_b );
    isa_ok( $md, 'DateTime::Lite::Duration' );
    is( $md->delta_months, 3, 'delta_md() 3 months' );

    my $ms = $dt_a->delta_ms( $dt_b );
    isa_ok( $ms, 'DateTime::Lite::Duration' );
    ok( $ms->delta_minutes > 0 || $ms->hours > 0, 'delta_ms() non-zero' );
};

# NOTE: compare_ignore_floating
subtest 'compare_ignore_floating' => sub
{
    my $dt_float = DateTime::Lite->new(
        year => 2026, month => 4, day => 3, hour => 14, minute => 30, second => 45
    );
    my $result = DateTime::Lite->compare_ignore_floating( $dt_float, $dt );
    ok( defined( $result ), 'compare_ignore_floating() defined' );
};

# NOTE: set_locale
subtest 'set_locale' => sub
{
    my $dt3 = $dt->clone;
    my $ret = $dt3->set_locale('en-US');
    is( $ret, $dt3, 'set_locale() returns self' );
};

# NOTE: fatal / error
subtest 'fatal / error' => sub
{
    my $dt3 = DateTime::Lite->new( year => 2026, time_zone => 'UTC' );
    ok( !$dt3->fatal, 'fatal() falsy by default' );

    local $SIG{__WARN__} = sub{};
    my $bad = DateTime::Lite->new( month => 6 );
    ok( !defined( $bad ), 'error path: returns undef' );
    my $err = DateTime::Lite->error;
    ok( defined( $err ) && length( "$err" ), 'error() set and stringifies' );
};

done_testing;

__END__


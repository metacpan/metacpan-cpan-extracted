# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime::Format::Lite - t/75.generated-locale.t
##----------------------------------------------------------------------------
# Round-trip tests for locale-sensitive tokens (%a, %A, %b, %B) across several
# locales. Each day (1-7) and month (1-12) is formatted with
# DateTime::Lite->strftime and then parsed back, verifying that the parsed
# values match the originals. This mirrors the generated-locale-* test files
# from DateTime::Format::Strptime.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use open ':std' => ':utf8';
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

# Locales to test. These are chosen to cover Latin, CJK, RTL-adjacent, and
# non-ASCII month/day names.
my @LOCALES = qw( en fr de ja pt );

foreach my $locale ( @LOCALES )
{
    subtest "locale: $locale" => sub
    {
        _test_days( $locale );
        _test_months( $locale );
    };
}

done_testing();

# NOTE: Test full weekday names (%A) for all 7 days
sub _test_days
{
    my $locale = shift( @_ );

    subtest 'weekday names %A' => sub
    {
        for my $dow ( 1..7 )
        {
            subtest( "day $dow" => sub{ _test_one_day( $locale, $dow ) } );
        }
    };
}

sub _test_one_day
{
    my( $locale, $dow ) = @_;

    my $pattern = '%Y-%m-%d %A';

    # Build a Monday-anchored date for the given day-of-week (1=Mon .. 7=Sun).
    # Use 2024-01-01 (Monday) as anchor.
    my $dt = DateTime::Lite->new(
        year   => 2024,
        month  => 1,
        day    => $dow,      # 1-Jan is Mon, so day N gives DoW N
        locale => $locale,
    );

    my $input = $dt->strftime( $pattern );
    ok( defined( $input ) && length( $input ), "strftime produced output for day $dow in $locale" ) or return;

    my $fmt = DateTime::Format::Lite->new(
        pattern  => $pattern,
        locale   => $locale,
        on_error => 'undef',
    );
    ok( defined( $fmt ), "constructor succeeded for pattern '$pattern' locale '$locale'" ) or return;

    my $parsed = $fmt->parse_datetime( $input );
    ok( defined( $parsed ), "parsed '$input'" ) or do
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
        return;
    };

    is( $parsed->year,        $dt->year,        'year preserved'  );
    is( $parsed->month,       $dt->month,       'month preserved' );
    is( $parsed->day,         $dt->day,         'day preserved'   );
    is( $parsed->day_of_week, $dt->day_of_week, 'day_of_week preserved' );
}

# NOTE: Test full month names (%B) for all 12 months
sub _test_months
{
    my $locale = shift( @_ );

    subtest 'month names %B' => sub
    {
        for my $month ( 1..12 )
        {
            subtest( "month $month" => sub{ _test_one_month( $locale, $month ) } );
        }
    };
}

sub _test_one_month
{
    my( $locale, $month ) = @_;

    my $pattern = '%Y-%B-%d';

    my $dt = DateTime::Lite->new(
        year   => 2024,
        month  => $month,
        day    => 15,
        locale => $locale,
    );

    my $input = $dt->strftime( $pattern );
    ok( defined( $input ) && length( $input ), "strftime produced output for month $month in $locale" ) or return;

    my $fmt = DateTime::Format::Lite->new(
        pattern  => $pattern,
        locale   => $locale,
        on_error => 'undef',
    );
    ok( defined( $fmt ), "constructor succeeded for pattern '$pattern' locale '$locale'" ) or return;

    my $parsed = $fmt->parse_datetime( $input );
    ok( defined( $parsed ), "parsed '$input'" ) or do
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
        return;
    };

    is( $parsed->year,  $dt->year,  'year preserved'  );
    is( $parsed->month, $dt->month, 'month preserved' );
    is( $parsed->day,   $dt->day,   'day preserved'   );
}

__END__

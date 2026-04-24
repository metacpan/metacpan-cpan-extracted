#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/20.dst_abolition.t
## Regression tests for offset_for_datetime() with timezones that abolished
## DST after having used it. GitLab issue #2, reported by Andrew Grechkin
## (@andrew-grechkin).
##
## The bug: the POSIX footer string was applied unconditionally, overwriting
## historically correct bounded DST spans with the post-abolition rule.
## Fix: the footer is now only applied when the matched span is open-ended
## (utc_end IS NULL), meaning the timestamp is beyond all stored transitions.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: Amsterdam: has DST, still active
subtest 'Europe/Amsterdam: DST still active' => sub
{
    my $tz = DateTime::Lite::TimeZone->new( name => 'Europe/Amsterdam' );
    ok( defined( $tz ), 'TimeZone object created' );

    my $offset_winter = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2021, month => 2, day => 1, time_zone => $tz )
    );
    my $offset_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2021, month => 5, day => 1, time_zone => $tz )
    );
    isnt( $offset_winter, $offset_summer, '2021: winter and summer offsets differ (DST active)' );
    is( $offset_winter, 3600,  '2021-02: CET = +0100 = 3600s' );
    is( $offset_summer, 7200,  '2021-05: CEST = +0200 = 7200s' );

    my $offset_future_winter = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 2, day => 1, time_zone => $tz )
    );
    my $offset_future_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 5, day => 1, time_zone => $tz )
    );
    isnt( $offset_future_winter, $offset_future_summer, '2026: winter and summer offsets differ (DST still active)' );
    is( $offset_future_winter, 3600, '2026-02: CET = +0100 = 3600s' );
    is( $offset_future_summer, 7200, '2026-05: CEST = +0200 = 7200s' );
};

# NOTE: Tehran: DST abolished September 2022
subtest 'Asia/Tehran: DST abolished 2022' => sub
{
    my $tz = DateTime::Lite::TimeZone->new( name => 'Asia/Tehran' );
    ok( defined( $tz ), 'TimeZone object created' );

    # Before DST season 2021 (DST starts ~21 March)
    my $offset_2021_winter = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2021, month => 2, day => 1, time_zone => $tz )
    );
    # During DST season 2021 (DST ends ~21 September)
    my $offset_2021_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2021, month => 5, day => 1, time_zone => $tz )
    );
    is( $offset_2021_winter, 12600, '2021-02: IRST = +0330 = 12600s (before DST)' );
    is( $offset_2021_summer, 16200, '2021-05: IRDT = +0430 = 16200s (DST active)' );
    isnt( $offset_2021_winter, $offset_2021_summer, '2021: winter and summer offsets differ (DST was active)' );

    # Last DST season 2022 (DST starts ~21 March, abolished ~21 September)
    my $offset_2022_winter = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2022, month => 2, day => 1, time_zone => $tz )
    );
    my $offset_2022_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2022, month => 5, day => 1, time_zone => $tz )
    );
    is( $offset_2022_winter, 12600, '2022-02: IRST = +0330 = 12600s (before last DST)' );
    is( $offset_2022_summer, 16200, '2022-05: IRDT = +0430 = 16200s (last DST season)' );

    # After DST abolition (September 2022 onwards)
    my $offset_2026_winter = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 2, day => 1, time_zone => $tz )
    );
    my $offset_2026_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 5, day => 1, time_zone => $tz )
    );
    is( $offset_2026_winter, 12600, '2026-02: +0330 = 12600s (post-abolition)' );
    is( $offset_2026_summer, 12600, '2026-05: +0330 = 12600s (post-abolition, no DST)' );
    is( $offset_2026_winter, $offset_2026_summer, '2026: winter and summer offsets equal (DST abolished)' );
};

# NOTE: Shanghai: DST abolished 1991
subtest 'Asia/Shanghai: DST abolished 1991' => sub
{
    my $tz = DateTime::Lite::TimeZone->new( name => 'Asia/Shanghai' );
    ok( defined( $tz ), 'TimeZone object created' );

    # DST was active April-September 1991 (+0900), standard is +0800
    my $offset_dst = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 1991, month => 6, day => 1, time_zone => $tz )
    );
    my $offset_std = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 1991, month => 11, day => 1, time_zone => $tz )
    );
    is( $offset_dst, 32400, '1991-06: CDT = +0900 = 32400s (DST active)' );
    is( $offset_std, 28800, '1991-11: CST = +0800 = 28800s (standard)' );

    # Post-abolition: always +0800
    my $offset_now = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 6, day => 1, time_zone => $tz )
    );
    is( $offset_now, 28800, '2026-06: CST = +0800 = 28800s (no DST)' );
};

# NOTE: Mexico City: DST abolished October 2022
subtest 'America/Mexico_City: DST abolished 2022' => sub
{
    my $tz = DateTime::Lite::TimeZone->new( name => 'America/Mexico_City' );
    ok( defined( $tz ), 'TimeZone object created' );

    # Last DST season: April-October 2022
    my $offset_2022_dst = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2022, month => 6, day => 1, time_zone => $tz )
    );
    my $offset_2022_std = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2022, month => 2, day => 1, time_zone => $tz )
    );
    is( $offset_2022_dst, -18000, '2022-06: CDT = -0500 = -18000s (last DST season)' );
    is( $offset_2022_std, -21600, '2022-02: CST = -0600 = -21600s (standard)' );

    # Post-abolition: always -0600
    my $offset_2026_summer = $tz->offset_for_datetime(
        DateTime::Lite->new( year => 2026, month => 6, day => 1, time_zone => $tz )
    );
    is( $offset_2026_summer, -21600, '2026-06: CST = -0600 = -21600s (no DST)' );
};

done_testing();

__END__

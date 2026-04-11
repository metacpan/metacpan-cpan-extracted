#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/07.set.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

# NOTE: Individual setters
subtest 'Individual setters' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 4,
        day       => 3,
        hour      => 12,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );

    $dt->set_year( 2026 );
    is( $dt->year, 2026, 'set_year' );

    $dt->set_month( 8 );
    is( $dt->month, 8, 'set_month' );

    $dt->set_day( 20 );
    is( $dt->day, 20, 'set_day' );

    $dt->set_hour( 9 );
    is( $dt->hour, 9, 'set_hour' );

    $dt->set_minute( 30 );
    is( $dt->minute, 30, 'set_minute' );

    $dt->set_second( 45 );
    is( $dt->second, 45, 'set_second' );

    $dt->set_nanosecond( 500_000_000 );
    is( $dt->nanosecond, 500_000_000, 'set_nanosecond' );
};

# NOTE: set() with multiple fields at once
subtest 'set() with multiple fields at once' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 1,
        day       => 1,
        time_zone => 'UTC'
    );

    $dt->set( month => 12, day => 25 );
    is( $dt->month, 12, 'set(): month' );
    is( $dt->day,   25, 'set(): day' );
    is( $dt->year,  2025, 'set(): year unchanged' );
};

# NOTE: set_time_zone - changing to a non-UTC zone
subtest 'set_time_zone - changing to a non-UTC zone' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 7,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );

    # UTC epoch at 2025-07-01T00:00:00Z
    my $utc_epoch = $dt->epoch;

    $dt->set_time_zone( 'Asia/Tokyo' );
    is( $dt->time_zone->name, 'Asia/Tokyo', 'set_time_zone to Asia/Tokyo' );
    # Local time in Tokyo is UTC+9, so should be 09:00:00
    is( $dt->hour, 9, 'Tokyo time is UTC+9' );
    # Epoch must not change when changing time zone
    is( $dt->epoch, $utc_epoch, 'epoch unchanged after set_time_zone' );
};

# NOTE: truncate - basic
subtest 'truncate - basic' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 6,
        day       => 15,
        hour      => 14,
        minute    => 30,
        second    => 45,
        time_zone => 'UTC',
    );

    my $dt2 = $dt->clone->truncate( to => 'minute' );
    is( $dt2->second, 0,  'truncate to minute: second zeroed' );
    is( $dt2->minute, 30, 'truncate to minute: minute kept' );
    is( $dt2->hour,   14, 'truncate to minute: hour kept' );

    my $dt3 = $dt->clone->truncate( to => 'day' );
    is( $dt3->hour,   0,  'truncate to day: hour zeroed' );
    is( $dt3->minute, 0,  'truncate to day: minute zeroed' );
    is( $dt3->day,    15, 'truncate to day: day kept' );
};

# NOTE: set_formatter
subtest 'set_formatter' => sub
{
    my $dt = DateTime::Lite->new(
        year => 2025, month => 4, day => 3, time_zone => 'UTC'
    );

    # A minimal formatter object
    my $fmt = bless {}, 'TestFormatter';
    {
        no strict 'refs';
        *{'TestFormatter::format_datetime'} = sub{ 'formatted!' };
    }

    $dt->set_formatter( $fmt );
    is( "$dt", 'formatted!', 'set_formatter: stringify uses formatter' );

    $dt->set_formatter( undef );
    like( "$dt", qr/2025/, 'set_formatter(undef): back to default stringify' );
};

done_testing;

__END__

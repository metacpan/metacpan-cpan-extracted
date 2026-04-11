#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/03.add_subtract.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::Duration' ) or BAIL_OUT( 'Cannot load DateTime::Lite::Duration' );

# NOTE: add() / subtract() - simple cases
subtest 'add() / subtract() - simple cases' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 1,
        day       => 15,
        time_zone => 'UTC',
    );

    my $dt2 = $dt->clone->add( days => 1 );
    is( $dt2->day, 16, 'add 1 day' );

    my $dt3 = $dt->clone->add( months => 1 );
    is( $dt3->month, 2, 'add 1 month' );

    my $dt4 = $dt->clone->add( years => 1 );
    is( $dt4->year, 2026, 'add 1 year' );

    my $dt5 = $dt->clone->subtract( days => 1 );
    is( $dt5->day, 14, 'subtract 1 day' );
};

# NOTE: Month-end handling: add months wraps correctly
subtest 'Month-end handling: add months wraps correctly' => sub
{
    my $dt = DateTime::Lite->new(
        year => 2025, month => 1, day => 31, time_zone => 'UTC'
    );
    my $dt2 = $dt->clone->add( months => 1 );
    # Feb has 28 days in 2025, wrap mode should give Feb 28 or Mar 3
    ok( defined( $dt2 ), 'add 1 month to Jan 31 survives' );
};

# NOTE: add_duration / subtract_duration
subtest 'add_duration / subtract_duration' => sub
{
    my $dt  = DateTime::Lite->new(
        year      => 2025,
        month     => 6,
        day       => 15,
        hour      => 12,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );
    my $dur = DateTime::Lite::Duration->new( hours => 3, minutes => 30 );

    my $dt2 = $dt->clone->add_duration( $dur );
    is( $dt2->hour,   15, 'add_duration: hour' );
    is( $dt2->minute, 30, 'add_duration: minute' );

    my $dt3 = $dt2->clone->subtract_duration( $dur );
    is( $dt3->hour,   12, 'subtract_duration: hour' );
    is( $dt3->minute, 0,  'subtract_duration: minute' );
};

# NOTE: subtract_datetime -> Duration
subtest 'subtract_datetime -> Duration' => sub
{
    my $dt1 = DateTime::Lite->new(
        year => 2025, month => 1, day => 1, time_zone => 'UTC'
    );
    my $dt2 = DateTime::Lite->new(
        year => 2025, month => 1, day => 11, time_zone => 'UTC'
    );

    my $dur = $dt2->subtract_datetime( $dt1 );
    isa_ok( $dur, 'DateTime::Lite::Duration' );
    is( $dur->delta_days, 10, 'subtract_datetime: 10 days difference' );
};

# NOTE: delta_days
subtest 'delta_days' => sub
{
    my $dt1 = DateTime::Lite->new(
        year => 2025, month => 3, day => 1, time_zone => 'UTC'
    );
    my $dt2 = DateTime::Lite->new(
        year => 2025, month => 3, day => 31, time_zone => 'UTC'
    );
    my $dur = $dt1->delta_days( $dt2 );
    is( $dur->delta_days, 30, 'delta_days: 30' );
};

# NOTE: Overloaded + / -
subtest 'Overloaded + / -' => sub
{
    my $dt  = DateTime::Lite->new(
        year      => 2025,
        month     => 4,
        day       => 1,
        time_zone => 'UTC'
    );
    my $dur = DateTime::Lite::Duration->new( days => 5 );

    my $dt2 = $dt + $dur;
    is( $dt2->day, 6, 'overloaded + works' );

    my $dt3 = $dt2 - $dur;
    is( $dt3->day, 1, 'overloaded - with Duration works' );

    my $diff = $dt2 - $dt;
    isa_ok( $diff, 'DateTime::Lite::Duration', 'overloaded - between two DTs gives Duration' );
    is( $diff->delta_days, 5, 'overloaded -: correct day count' );
};

# NOTE: subtract_datetime_absolute
subtest 'subtract_datetime_absolute' => sub
{
    my $dt1 = DateTime::Lite->new(
        year      => 2025,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );
    my $dt2 = DateTime::Lite->new(
        year      => 2025,
        month     => 1,
        day       => 2,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );
    my $dur = $dt2->subtract_datetime_absolute( $dt1 );
    is( $dur->delta_seconds, 86400, 'subtract_datetime_absolute: 86400 seconds in a day' );
};

# NOTE: truncate
subtest 'truncate' => sub
{
    my $dt = DateTime::Lite->new(
        year       => 2025,
        month      => 6,
        day        => 15,
        hour       => 14,
        minute     => 30,
        second     => 45,
        nanosecond => 123_000_000,
        time_zone  => 'UTC',
    );

    my $dt2 = $dt->clone->truncate( to => 'hour' );
    is( $dt2->hour,   14, 'truncate to hour: hour' );
    is( $dt2->minute, 0,  'truncate to hour: minute zeroed' );
    is( $dt2->second, 0,  'truncate to hour: second zeroed' );

    my $dt3 = $dt->clone->truncate( to => 'day' );
    is( $dt3->hour, 0, 'truncate to day: hour zeroed' );
    is( $dt3->day,  15, 'truncate to day: day unchanged' );

    my $dt4 = $dt->clone->truncate( to => 'month' );
    is( $dt4->day,  1, 'truncate to month: day is 1' );
    is( $dt4->month, 6, 'truncate to month: month unchanged' );

    my $dt5 = $dt->clone->truncate( to => 'year' );
    is( $dt5->month, 1, 'truncate to year: month is 1' );
    is( $dt5->year,  2025, 'truncate to year: year unchanged' );
};

done_testing;

__END__

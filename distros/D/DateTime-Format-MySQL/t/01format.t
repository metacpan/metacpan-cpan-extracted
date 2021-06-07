use strict;

use Test::More tests => 7;

use DateTime::Format::MySQL;

my $mysql = 'DateTime::Format::MySQL';

my $dt = DateTime->new( year   => 2000,
                        month  => 5,
                        day    => 6,
                        hour   => 15,
                        minute => 23,
                        second => 44,
                        time_zone => 'UTC',
                      );

{
    is( $mysql->format_date($dt), '2000-05-06', 'format_date' );
    is( $mysql->format_datetime($dt), '2000-05-06 15:23:44', 'format_datetime' );
    is( $mysql->format_time($dt), '15:23:44', 'format_time' );
}

my $dt_hires = DateTime->new( year   => 2000,
                        month  => 5,
                        day    => 6,
                        hour   => 15,
                        minute => 23,
                        second => 44,
                        nanosecond => 123_456_000,
                        time_zone => 'UTC',
                      );

{
    is( $mysql->format_time($dt_hires), '15:23:44.123456', 'format_time hires keeps micros');

    $dt_hires->set(nanosecond => 123_456_789);
    is( $mysql->format_time($dt_hires), '15:23:44.123456', 'format_time hires truncates nanos');

    $dt_hires->set(nanosecond => 1);
    is( $mysql->format_time($dt_hires), '15:23:44', 'format_time hires drops nanos < 1 micro');

    $dt_hires->set(nanosecond => 500_000_000);
    is( $mysql->format_time($dt_hires), '15:23:44.500000', 'format_time hires keeps 6 digit precision');
}

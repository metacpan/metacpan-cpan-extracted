use strict;

use Test::More tests => 3;

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

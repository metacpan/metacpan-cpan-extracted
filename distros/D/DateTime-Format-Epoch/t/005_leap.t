use strict;
BEGIN { $^W = 1 }

use Test::More tests => 10;
use DateTime;
use DateTime::Format::Epoch;

my $dt = DateTime->new( year  => 1970, month => 1, day   => 1 );

my $f_with_leap = DateTime::Format::Epoch->new( epoch => $dt,
                                                skip_leap_seconds => 0 );
my $f_skip_leap = DateTime::Format::Epoch->new( epoch => $dt,
                                                skip_leap_seconds => 1 );

isa_ok($f_with_leap, 'DateTime::Format::Epoch' );

is($f_with_leap->format_datetime($dt), 0, 'Epoch = 0');

$dt->set( hour => 1 );
is($f_with_leap->format_datetime($dt), 3600, 'Epoch + 1hour');

$dt->set( day => 2, hour => 0 );
is($f_with_leap->format_datetime($dt), 24*3600, 'Epoch + 1day');

$dt = DateTime->new( year => 2003, month => 4, day => 27,
                     hour => 21, minute => 9, second => 57,
                     time_zone => 'Europe/Amsterdam' );

is($f_with_leap->format_datetime($dt) - $f_skip_leap->format_datetime($dt),
    22, '22 leap seconds until 2003');

$dt = DateTime->new( year => 1994, month => 6, day => 30,
                     hour => 23, minute => 59 );
my $dt2 = DateTime->new( year => 1994, month => 7, day => 1,
                         hour => 0, minute => 1 );
is($f_with_leap->format_datetime($dt2) - $f_with_leap->format_datetime($dt),
    121, '121 secs in 2 minutes');
is($f_skip_leap->format_datetime($dt2) - $f_skip_leap->format_datetime($dt),
    120, '120 secs counted in 2 minutes');

$dt2 = DateTime->new( year => 1994, month => 6, day => 30,
                      hour => 23, minute => 59, second => 60,
                      time_zone => 'UTC' );

is($f_with_leap->format_datetime($dt2) - $f_with_leap->format_datetime($dt),
    60, 'correct value at leap second');

# (epoch count at leap second is not specified if skip_leap_seconds is
# true, so not tested)

# epoch is leap second
my $f = DateTime::Format::Epoch->new( epoch => $dt2,
                                      skip_leap_seconds => 0 );
is($f->format_datetime($dt), -60, 'epoch -60 before leap second');

$dt = DateTime->new( year => 1994, month => 7, day => 1,
                     hour => 0, minute => 1 );
is($f->format_datetime($dt), 61, 'epoch 61 after leap second');

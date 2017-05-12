use strict;
BEGIN { $^W = 1 }

use Test::More tests => 3;
use DateTime;
use DateTime::Format::Epoch;

my $dt = DateTime->new( year  => 1970, month => 1, day   => 1 );

my $f = DateTime::Format::Epoch->new( epoch => $dt );

is($f->parse_datetime(0)->datetime, $dt->datetime, '0 = Epoch');

$dt = DateTime->new( year => 2003, month => 4, day => 27,
                     hour => 21, minute => 9, second => 57,
                     nanosecond => 8e8, time_zone => 'Europe/Amsterdam' );

is($f->parse_datetime(1051470597)->datetime, '2003-04-27T19:09:57',
    '"now"');

$dt = DateTime->new( year => 1969, month => 12, day => 22 );
is($f->parse_datetime(-10*24*3600)->datetime, '1969-12-22T00:00:00',
    'Epoch - 10days');

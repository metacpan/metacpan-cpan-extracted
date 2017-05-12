use strict;
BEGIN { $^W = 1 }

use Test::More tests => 6;
use DateTime;
use DateTime::Format::Epoch;

my $dt = DateTime->new( year  => 1970, month => 1, day   => 1 );

my $f = DateTime::Format::Epoch->new( epoch => $dt, dhms => 1,
                                      skip_leap_seconds => 0 );

isa_ok($f, 'DateTime::Format::Epoch' );

ok(eq_array([$f->format_datetime($dt)], [0,0,0,0]),
   'Epoch = 0/0:0:0');

$dt->set( hour => 1 );
ok(eq_array([$f->format_datetime($dt)], [0,1,0,0]),
  'Epoch + 1hour');

$dt->set( day => 2, hour => 0 );
ok(eq_array([$f->format_datetime($dt)], [1,0,0,0]),
  'Epoch + 1 day');

$dt = DateTime->new( year => 1973, month => 1, day => 2 );
ok(eq_array([$f->format_datetime($dt)], [365*2+366+1,0,0,2]),
  'Leap second counted');

$dt = DateTime->new( year => 1969, month => 12, day => 22, hour => 22 );
ok(eq_array([$f->format_datetime($dt)], [-9, -2, 0, 0]),
  'Epoch - 9days 2hours');

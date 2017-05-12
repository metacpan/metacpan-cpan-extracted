use strict;
use Test::More;
use Data::OpeningHours 'is_open';
use Data::OpeningHours::Calendar;

my $calendar = Data::OpeningHours::Calendar->new();

ok($calendar);
isa_ok($calendar, 'Data::OpeningHours::Calendar');

$calendar->set_week_day(1 => []);
$calendar->set_week_day(2 => []);
$calendar->set_week_day(3 => [ ['10:00','12:00'] ]);
$calendar->set_week_day(4 => [ ['10:00','12:00'] ]);
$calendar->set_week_day(5 => []);
$calendar->set_week_day(6 => []);
$calendar->set_week_day(7 => [ [ '10:00', '12:00' ], ['14:00','16:00'] ]);

ok(!$calendar->is_open_on_week_day(1, '10:00'));
ok(!$calendar->is_open_on_week_day(2, '10:00'));
ok($calendar->is_open_on_week_day(3, '10:30'));
ok($calendar->is_open_on_week_day(7, '11:30'));
ok($calendar->is_open_on_week_day(7, '10:00'));
ok($calendar->is_open_on_week_day(7, '15:00'));
ok($calendar->is_open_on_week_day(7, '15:01'));
ok($calendar->is_open_on_week_day(7, '15:59'));

$calendar->set_special_day('2012-01-01' => []);
$calendar->set_special_day('2012-01-02' => []);
$calendar->set_special_day('2012-01-03' => [ ['10:00','12:00'] ]);

ok(!$calendar->is_open_on_special_day('2012-01-01', '10:00'));
ok(!$calendar->is_open_on_special_day('2012-01-02', '10:00'));
ok($calendar->is_open_on_special_day('2012-01-03', '10:00'));

ok($calendar->is_open(DateTime->new(
    year   => 2012,
    month  => 5,
    day    => 17,
    hour   => 10,
    minute => 30,
    second => 0,
)));
ok(!$calendar->is_open(DateTime->new(
    year   => 2012,
    month  => 5,
    day    => 14,
    hour   => 10,
    minute => 30,
    second => 0,
)));
ok(!$calendar->is_open(DateTime->new(
    year   => 2012,
    month  => 1,
    day    => 1,
    hour   => 10,
    minute => 30,
    second => 0,
)));
ok($calendar->is_open(DateTime->new(
    year   => 2012,
    month  => 1,
    day    => 3,
    hour   => 10,
    minute => 30,
    second => 0,
)));


done_testing();


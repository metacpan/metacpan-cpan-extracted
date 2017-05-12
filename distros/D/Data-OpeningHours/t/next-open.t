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

$calendar->set_special_day('2012-01-01' => []);
$calendar->set_special_day('2012-01-02' => []);
$calendar->set_special_day('2012-01-03' => [ ['10:00','12:00'] ]);

my $next_open = $calendar->next_open(DateTime->new(
    year   => 2012,
    month  => 1,
    day    => 2,
    hour   => 16,
    minute => 30,
    second => 0,
));
is($next_open->year, 2012);
is($next_open->month, 1);
is($next_open->day, 3);
is($next_open->hour, 10);
is($next_open->minute, 0);

$next_open = $calendar->next_open(DateTime->new(
    year   => 2012,
    month  => 1,
    day    => 3,
    hour   => 16,
    minute => 30,
    second => 0,
));
is($next_open->year, 2012);
is($next_open->month, 1);
is($next_open->day, 4);
is($next_open->hour, 10);
is($next_open->minute, 0);

$next_open = $calendar->next_open(DateTime->new(
    year   => 2012,
    month  => 1,
    day    => 5,
    hour   => 16,
    minute => 30,
    second => 0,
));
is($next_open->year, 2012);
is($next_open->month, 1);
is($next_open->day, 8);
is($next_open->hour, 10);
is($next_open->minute, 0);

done_testing();


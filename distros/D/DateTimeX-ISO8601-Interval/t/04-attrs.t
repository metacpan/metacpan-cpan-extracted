use strict;
use warnings;
use Test::More qw(no_plan);

use DateTimeX::ISO8601::Interval;

my $interval = DateTimeX::ISO8601::Interval->new(
	start => DateTime->new(year => 2013, month => 12, day => 1),
	duration => DateTime::Duration->new( months => 1)
);

isa_ok $interval, 'DateTimeX::ISO8601::Interval';
isa_ok $interval->start, 'DateTime', 'start';
isa_ok $interval->end, 'DateTime', 'end';
isa_ok $interval->duration, 'DateTime::Duration', 'duration';
is $interval->repeat, 0, 'no repeat';

$interval->start( '2013-12-02');
is $interval->start->ymd, '2013-12-02', 'start setter';

$interval->end( '2013-12-09');
is $interval->end->ymd, '2013-12-10', 'end setter, moves to next day when precision is "date"';
is $interval->duration->weeks, 1, 'duration adjusted';

$interval->end(DateTime->new( year => 2013, month => 12, day => 9));
is $interval->end->ymd, '2013-12-09', 'end setter, leaves alone if DateTime provided';

$interval->end( '2013-12-09T11:00:23');
is $interval->end->ymd, '2013-12-09', 'end setter, leaves alone if time specified';

$interval->repeat(5);
is $interval->repeat, 5, 'repeat setter';

$interval->set_time_zone('America/New_York');
is $interval->start->time_zone->name, 'America/New_York', 'expected time_zone';

$interval = DateTimeX::ISO8601::Interval->new(
	end => DateTime->new(year => 2013, month => 12, day => 1),
	duration => DateTime::Duration->new( months => 1)
);
ok exists $interval->{duration}, 'duration set';

is $interval->duration->months, 1, 'interval == 1 month';
is $interval->start->ymd, '2013-11-01', 'expected start date';

$interval->start('2013-11-30');
is $interval->duration->days, 2, 'interval is for two days';
ok !exists $interval->{duration}, 'duration no longer set';

my $success = eval { $interval->duration(DateTime::Duration->new( months => 1)); 1 };
ok !$success, 'duration not set-able when start/end already set';
delete $interval->{end};

$success = eval { $interval->duration('garbage'); 1 };
ok !$success, 'duration not set-able with invalid duration';

$interval->duration(DateTime::Duration->new( months => 1));
is $interval->duration->months, 1, 'duration set';

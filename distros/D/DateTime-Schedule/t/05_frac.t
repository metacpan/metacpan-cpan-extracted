use v5.26;
use warnings;

use Test2::V0;

use DateTime::Schedule;
use DateTime::Schedule::Weekly;

my $ds;

my $start = DateTime->new(year => 2000, month => 1, day => 3);
my $end   = DateTime->new(year => 2000, month => 1, day => 10, hour => 12, minute => 1, second => 0);

$ds = DateTime::Schedule->new(portion => 1);
is($ds->days_in_range($start, $end)->count, 7, 'whole day');

$ds = DateTime::Schedule->new(portion => 0.66);
is($ds->days_in_range($start, $end)->count, 7, '2/3rds');

$ds = DateTime::Schedule->new(portion => 0.5);
is($ds->days_in_range($start, $end)->count, 8, 'half day');


$ds = DateTime::Schedule::Weekly->weekdays(portion => 1);
is($ds->days_in_range($start, $end)->count, 5, 'weekdays: whole day');

$ds = DateTime::Schedule::Weekly->weekdays(portion => 0.66);
is($ds->days_in_range($start, $end)->count, 5, 'weekdays: 2/3rds');

$ds = DateTime::Schedule::Weekly->weekdays(portion => 0.5);
is($ds->days_in_range($start, $end)->count, 6, 'weekdays: half day');

done_testing;

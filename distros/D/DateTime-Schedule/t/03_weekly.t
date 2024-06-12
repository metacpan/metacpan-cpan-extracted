use v5.26;
use warnings;

use Test2::V0;

use DateTime::Schedule::Weekly;

my $start = DateTime->new(year => 2000, month => 1, day => 1);    # Saturday

sub plus_one_day()          {$start->clone->add(days  => 1)}
sub plus_three_days()       {$start->clone->add(days  => 3)}
sub plus_one_week()         {$start->clone->add(weeks => 1)}
sub plus_one_hundred_days() {$start->clone->add(days  => 100)}

my $dts = DateTime::Schedule::Weekly->new;

is($dts->days_in_range($start, plus_one_day)->count,          1,   'one day, all on');
is($dts->days_in_range($start, plus_three_days)->count,       3,   'three days, all on');
is($dts->days_in_range($start, plus_one_week)->count,         7,   'one week, all on');
is($dts->days_in_range($start, plus_one_hundred_days)->count, 100, 'one hundred days, all on');

# ==============================================================================

$dts = DateTime::Schedule::Weekly->weekends();

is($dts->days_in_range($start, plus_one_day)->count,          1,  'one day, weekends');
is($dts->days_in_range($start, plus_three_days)->count,       2,  'three days, weekends');
is($dts->days_in_range($start, plus_one_week)->count,         2,  'one week, weekends');
is($dts->days_in_range($start, plus_one_hundred_days)->count, 30, 'one hundred days, weekends');

# ==============================================================================

$dts = DateTime::Schedule::Weekly->weekends(monday => 1);

is($dts->days_in_range($start, plus_one_day)->count,          1,  'one day, weekends, plus mondays');
is($dts->days_in_range($start, plus_three_days)->count,       3,  'three days, weekends, plus mondays');
is($dts->days_in_range($start, plus_one_week)->count,         3,  'one week, weekends, plus mondays');
is($dts->days_in_range($start, plus_one_hundred_days)->count, 44, 'one hundred days, weekends, plus mondays');

# ==============================================================================

$dts = DateTime::Schedule::Weekly->weekdays();

is($dts->days_in_range($start, plus_one_day)->count,          0,  'one day, weekdays');
is($dts->days_in_range($start, plus_three_days)->count,       1,  'three days, weekdays');
is($dts->days_in_range($start, plus_one_week)->count,         5,  'one week, weekdays');
is($dts->days_in_range($start, plus_one_hundred_days)->count, 70, 'one hundred days, weekdays');

# ==============================================================================

$dts = DateTime::Schedule::Weekly->weekdays(monday => 0);

is($dts->days_in_range($start, plus_one_day)->count,          0,  'one day, weekdays, except mondays');
is($dts->days_in_range($start, plus_three_days)->count,       0,  'three days, weekdays, except mondays');
is($dts->days_in_range($start, plus_one_week)->count,         4,  'one week, weekdays, except mondays');
is($dts->days_in_range($start, plus_one_hundred_days)->count, 56, 'one hundred days, weekdays, except mondays');

done_testing;

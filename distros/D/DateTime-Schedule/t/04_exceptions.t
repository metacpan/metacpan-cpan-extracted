use v5.26;
use warnings;

use Test2::V0;

use DateTime::Schedule::Weekly;

my $dts = DateTime::Schedule::Weekly->weekdays();

ok(dies {push($dts->exclude->@*, DateTime->now)}, 'exclude is a read-only array');

my $start = DateTime->new(year => 2000, month => 1, day => 3);     # Monday
my $end   = DateTime->new(year => 2000, month => 1, day => 31);    # 4 weeks later

is($dts->days_in_range($start, $end)->count, 20, 'weekdays in 4 weeks');

$dts = DateTime::Schedule::Weekly->weekdays(exclude => [DateTime->new(year => 2000, month => 1, day => 3)]);

is($dts->days_in_range($start, $end)->count, 19, 'weekdays in 4 weeks, minus one');

$dts = DateTime::Schedule::Weekly->weekdays(
  exclude => [
    DateTime->new(year => 2000, month => 1, day => 3),
    DateTime->new(year => 2000, month => 1, day => 1),    #out of range low
  ]
);

is($dts->days_in_range($start, $end)->count, 19, 'weekdays in 4 weeks, out of lower bound exception');

$dts = DateTime::Schedule::Weekly->weekdays(
  exclude => [
    DateTime->new(year => 2000, month => 1, day => 3),
    DateTime->new(year => 2000, month => 1, day => 1),
    DateTime->new(year => 2000, month => 1, day => 31),    #out of range high
  ]
);

is($dts->days_in_range($start, $end)->count, 19, 'weekdays in 4 weeks, out of upper bound exception');

$dts = DateTime::Schedule::Weekly->weekdays(
  exclude => [
    DateTime->new(year => 2000, month => 1, day => 3),
    DateTime->new(year => 2000, month => 1, day => 1),
    DateTime->new(year => 2000, month => 1, day => 31),
    DateTime->new(year => 2000, month => 1, day => 17),    # another scheduling exception
  ]
);

is($dts->days_in_range($start, $end)->count, 18, 'weekdays in 4 weeks, two exclude');

$dts = DateTime::Schedule::Weekly->weekends();
is($dts->days_in_range($start, $end)->count, 8, 'no inclusions');

$dts = DateTime::Schedule::Weekly->weekends(include => [DateTime->new(year => 2000, month => 1, day => 3)]);

is($dts->days_in_range($start, $end)->count, 9, 'include monday');

$dts = DateTime::Schedule::Weekly->weekends(
  include => [DateTime->new(year => 2000, month => 1, day => 3)],
  exclude => [DateTime->new(year => 2000, month => 1, day => 3)]
);

is($dts->days_in_range($start, $end)->count, 8, 'exclusion priority');

done_testing;

use strict;
use warnings;
use Test::More;

use DateTimeX::Factory;

my @time_zones = qw(
    Asia/Tokyo
    UTC
    floating
);

for my $tz (@time_zones) {
    my $factory = DateTimeX::Factory->new(
        time_zone => $tz,
    );
    my $dt = $factory->now;
    is($dt => DateTime->now(time_zone => $tz), "Correct now instance $tz from instance method");
    $dt = $factory->today;
    is($dt => DateTime->today(time_zone => $tz), "Correct today instance $tz from instance method");
    $dt = $factory->yesterday;
    is($dt => DateTime->today(time_zone => $tz)->subtract(days => 1), "Correct yesterday instance $tz from instance method");
    $dt = $factory->tommorow;
    is($dt => DateTime->today(time_zone => $tz)->add(days => 1), "Correct tommorow instance $tz from instance method");
    $dt = $factory->from_epoch(epoch => 100000000);
    is($dt => DateTime->from_epoch(epoch => 100000000, time_zone => $tz), "Correct from_epoch instance $tz from instance method");
    $dt = $factory->last_day_of_month(year => 2012, month => 2);
    is($dt => DateTime->last_day_of_month(year => 2012, month => 2, time_zone => $tz), "Correct last_day_of_month instance $tz from instance method");
    $dt = $factory->from_day_of_year(year => 2012, day_of_year => 100);
    is($dt => DateTime->from_day_of_year(year => 2012, day_of_year => 100, time_zone => $tz), "Correct day_of_year instance $tz from instance method");
}

done_testing;

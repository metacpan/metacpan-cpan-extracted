use strict;
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
    my $fmt = '%Y%m%d%H%M%S';
    my $strptime_dt = $factory->strptime($dt->strftime($fmt), $fmt);
    is($dt => $strptime_dt, "strptime successful");
    $fmt = '%Y-%m-%d %H:%M:%S';
    my $datetime = $factory->from_mysql_datetime($dt->strftime($fmt));
    is($dt => $datetime, "from_mysql_datetime successful");
    $fmt = '%Y-%m-%d';
    my $date = $factory->from_mysql_date($dt->strftime($fmt));
    is($dt->clone->truncate(to => 'day') => $date, "from_mysql_date successful");
    $fmt = '%Y/%m/%d';
    my $ymd = $factory->from_ymd($dt->strftime($fmt), '/');
    is($dt->clone->truncate(to => 'day') => $ymd, "from_ymd successful");
}

done_testing;

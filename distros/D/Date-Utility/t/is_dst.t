#!perl

use strict;
use warnings;

use Test::More;
use Date::Utility;
use DateTime;

my $begin = time - 366 * 24 * 3600;                                                                       # about 1y back
my $range = 10 * 366 * 24 * 3600;                                                                         # about 10y
my @zones = (qw!Europe/London Europe/Berlin Asia/Tehran America/New_York Asia/Tokyo Australia/Sydney!);

sub is_dst_in_zone_old {
    my ($epoch, $timezone) = @_;

    my $dt = DateTime->from_epoch(
        epoch     => $epoch,
        time_zone => $timezone
    );

    return $dt->is_dst;
}

for (1 .. 200000) {
    my $tm = $begin + int rand $range;
    my $tz = $zones[int rand(0 + @zones)];
    is +Date::Utility->new($tm)->is_dst_in_zone($tz), is_dst_in_zone_old($tm, $tz), "time=$tm tz=$tz";
}

done_testing;

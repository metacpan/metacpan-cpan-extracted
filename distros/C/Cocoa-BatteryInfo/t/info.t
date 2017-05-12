use strict;
use warnings;
use Test::More;

my $model = qx{ system_profiler SPHardwareDataType };
unless ($model =~ /MacBook/) {
    plan skip_all => 'Skip test unless hardware is not notebooks';
}

use Cocoa::BatteryInfo;

my $info = Cocoa::BatteryInfo->info;
ok ref $info eq 'HASH', 'hashref ok';
ok $info->{Name}, 'name is ok';

my @sources = Cocoa::BatteryInfo->sources;
ok scalar @sources, 'sources ok';
my $info2 = Cocoa::BatteryInfo->info($sources[0]);
is_deeply $info2, $info, 'info with source ok';

my $sec = Cocoa::BatteryInfo->time_remaining_estimate;
ok $sec, 'time_remaining_estimate ok';

my $level = Cocoa::BatteryInfo->battery_warning_level;
ok $level, 'battery_warning_level ok';

ok $level == Cocoa::BatteryInfo::LowBatteryWarningNone
 || $level == Cocoa::BatteryInfo::LowBatteryWarningEarly
 || $level == Cocoa::BatteryInfo::LowBatteryWarningFinal, 'warning level is ok';

done_testing;

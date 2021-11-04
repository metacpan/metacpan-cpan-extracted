#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( "Acme::FishFarm::WaterLevelMaintainer" ) || BAIL_OUT;
}

my $water_level = Acme::FishFarm::WaterLevelMaintainer->install;
is( $water_level->current_water_level, 5, "Correct default water level" );
$water_level->current_water_level(10);
is( $water_level->current_water_level, 10, "Correct new water level" );

is( $water_level->low_water_level_threshold, 2, "Correct default water level threshold" );
is( $water_level->water_level_increase_height, 0.5, "Correct default water level to increase" );

$water_level->set_low_water_level_threshold(5);
$water_level->set_water_level_increase_height(1.2);
is( $water_level->low_water_level_threshold, 5, "Correct new water level threshold" );
is( $water_level->water_level_increase_height, 1.2, "Correct new water level to increase" );

$water_level->pump_water_in; # 10+1.2=11.2
is( $water_level->current_water_level, 11.2, "Correct height after pumping water" );
is( $water_level->is_low_water_level, 0, "Water level not low yet" );
$water_level->current_water_level(3);
is( $water_level->is_low_water_level, 1, "Time to pump water in!" );


done_testing;

# besiyata d'shmaya




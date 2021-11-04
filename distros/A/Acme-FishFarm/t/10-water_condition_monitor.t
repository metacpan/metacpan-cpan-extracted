#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( "Acme::FishFarm::WaterConditionMonitor" ) || BAIL_OUT;
    use_ok( "Acme::FishFarm::OxygenMaintainer" ) || BAIL_OUT;
}

my $water_monitor = Acme::FishFarm::WaterConditionMonitor->install();

is( ref($water_monitor), "Acme::FishFarm::WaterConditionMonitor", "Correct class" );

# pH, current: 7, [6.5, 7.5]
my $ph_range =  $water_monitor->ph_threshold;
is( $ph_range->[0], 6.5, "Correct min pH" );
is( $ph_range->[1], 7.5, "Correct max pH" ); 

ok($water_monitor->set_ph_threshold([4, 7]), "New pH can be set");
my $new_ph_range =  $water_monitor->ph_threshold;
is( $new_ph_range->[0], 4, "Correct new min pH" );
is( $new_ph_range->[1], 7, "Correct new max pH" );
# current: 7, [4, 7]

my $current_ph = $water_monitor->current_ph;
is( $current_ph, 7, "Correct default pH value");
is( $water_monitor->ph_is_normal, 1, "pH level is normal" );
is( $water_monitor->is_on_LED_pH, 0, "pH LED is not on" );
is( $water_monitor->is_on_buzzer_short, 0, "pH sensor not making short buzzer turn on" );
# current: 7, [4, 7]

# temperature
my $temperature_range =  $water_monitor->temperature_threshold;
is( $temperature_range->[0], 20, "Correct min temperature" );
is( $temperature_range->[1], 25, "Correct max temperature" );

ok($water_monitor->set_temperature_threshold([15, 20]), "New pH can be set");
my $new_temperature_range =  $water_monitor->temperature_threshold;
is( $new_temperature_range->[0], 15, "Correct new min temperature" );
is( $new_temperature_range->[1], 20, "Correct new max temperature" );

my $current_temperature = $water_monitor->current_temperature;
is( $current_temperature, 23, "Correct default temperature value");
isnt( $water_monitor->temperature_is_normal, 1, "Temperature is not normal right now" );
is( $water_monitor->is_on_LED_temperature, 1, "Temperature LED is on" );
is( $water_monitor->is_on_buzzer_short, 1, "Temperature sensor is turning on short buzzer" );

isnt ( $water_monitor->is_on_buzzer_long , 1, "Long buzzer is not switched on yet, nice");

print "Short buzzer on: ", $water_monitor->{short_buzzer_on}, "\n";
print "Long buzzer on: ", $water_monitor->{long_buzzer_on}, "\n";
is( $water_monitor->lighted_LED_count, 1, "1 LED lighted up" );

# try to make the long buzzer switch on and off again
# must check for normal state before checking the LEDs and buzzers
$water_monitor->current_ph(8);
is( $water_monitor->current_ph, 8, "Correct new pH value" );
$water_monitor->ph_is_normal;
is( $water_monitor->is_on_LED_pH, 1, "pH LED is on" );
is( $water_monitor->is_on_buzzer_short, 0, "More than 1 LEDs, long buzzer is enough" );

print "Short buzzer on: ", $water_monitor->{short_buzzer_on}, "\n";
print "Long buzzer on: ", $water_monitor->{long_buzzer_on}, "\n";
is( $water_monitor->lighted_LED_count, 2, "2 LEDs lighted up" );

# temperature and pH both not normal, long buzzer should go off
is( $water_monitor->is_on_buzzer_long, 1, "pH and temperature caused long buzzer to go off" );

# turbidity
is( $water_monitor->current_turbidity, 10, "Correct default current turbidity");
is( $water_monitor->turbidity_threshold, 180, "Correct default turbidity threshold");

$water_monitor->set_turbidity_threshold(300);
is( $water_monitor->turbidity_threshold, 300, "Correct new turbidity threshold");

$water_monitor->current_turbidity(130);
is( $water_monitor->current_turbidity, 130, "Correct new current turbidity");

# make LED and buzzer fire
$water_monitor->set_turbidity_threshold(100);
is( $water_monitor->water_dirty, 1, "Water is dirty");

# lighted LED shuold be 3 by now
is( $water_monitor->is_on_LED_turbidity, 1, "Turbidity LED is on" );
is( $water_monitor->lighted_LED_count, 3, "3 LEDs lighted up");

is( $water_monitor->is_on_buzzer_short, 0, "Short buzzer not on anymore");
is( $water_monitor->is_on_buzzer_long, 1, "3 LEDs, long buzzer still on" );

# oxygen level
# this will need the oxygen maintainer to be connected to the monitoring system
my $oxygen = Acme::FishFarm::OxygenMaintainer->install( current_DO => 1 ); # lacking oxygen
$water_monitor->add_oxygen_maintainer( $oxygen );
is( $water_monitor->lacking_oxygen, 1, "Fish is lacking oxygen");
is( $water_monitor->lighted_LED_count, 4, "Low DO causing 4th LED to light up");
is( $water_monitor->is_on_buzzer_long, 1, "4 LEDs, long buzzer still on" );

# reduce LEDs
my $water_monitor_2 = Acme::FishFarm::WaterConditionMonitor->install;
my $oxygen_2 = Acme::FishFarm::OxygenMaintainer->install( current_DO => 1 ); # lacking oxygen
$water_monitor_2->add_oxygen_maintainer( $oxygen_2 );

is( $water_monitor_2->lacking_oxygen, 1, "Lacking oxygen" );
is( $water_monitor_2->lighted_LED_count, 1, "1 LED lighted by low O2" );
is( $water_monitor_2->is_on_buzzer_short, 1, "Short buzz" );
is( $water_monitor_2->is_on_buzzer_long, 0, "Long buzzer is still quite");

# pH out of range
$water_monitor_2->current_ph(13);
is( $water_monitor_2->ph_is_normal, 0, "Abnormal pH" );
is( $water_monitor_2->lighted_LED_count, 2, "1 LED lighted by low O2" );
is( $water_monitor_2->is_on_buzzer_short, 0, "2 LEDs, short buzz off" );
is( $water_monitor_2->is_on_buzzer_long, 1, "2 LEDs, short buzz off" );

print "Short buzzer on: ", $water_monitor->{short_buzzer_on}, "\n";
print "Long buzzer on: ", $water_monitor->{long_buzzer_on}, "\n";

# temperature out of range
$water_monitor_2->current_temperature(45);
is( $water_monitor_2->temperature_is_normal, 0, "Abnormal pH" );
is( $water_monitor_2->lighted_LED_count, 3, "1 LED lighted by low O2" );
is( $water_monitor_2->is_on_buzzer_short, 0, "3 LEDs, short buzz off" );
is( $water_monitor_2->is_on_buzzer_long, 1, "3 LEDs, short buzz off" );

print "Short buzzer on: ", $water_monitor_2->{short_buzzer_on}, "\n";
print "Long buzzer on: ", $water_monitor_2->{long_buzzer_on}, "\n";

# water dirty
$water_monitor_2->current_turbidity(300);
is( $water_monitor_2->water_dirty, 1, "Water is dirty");
is( $water_monitor_2->is_on_LED_turbidity, 1, "Turbidity LED is on" );
is( $water_monitor_2->lighted_LED_count, 4, "4 LEDs lighted up");
is( $water_monitor_2->is_on_buzzer_short, 0, "Short buzzer not on anymore");
is( $water_monitor_2->is_on_buzzer_long, 1, "4 LEDs, long buzzer still on" );

print "Short buzzer on: ", $water_monitor_2->{short_buzzer_on}, "\n";
print "Long buzzer on: ", $water_monitor_2->{long_buzzer_on}, "\n";
# make everything normal

$oxygen_2->current_DO(8); # threshold is 5
is( $water_monitor_2->lacking_oxygen, 0, "DO level back to normal");
is( $water_monitor_2->lighted_LED_count, 3, "3 LEDs left");
is( $water_monitor_2->is_on_buzzer_long, 1, "3 LEDs, long buzzer still on" );
is( $water_monitor_2->is_on_buzzer_short, 0, "Short buzzer not on anymore");

$water_monitor_2->current_ph(7); # range is [6.5, 7.5]
is( $water_monitor_2->ph_is_normal, 1, "pH back to normal" );
is( $water_monitor_2->lighted_LED_count, 2, "2 LEDs lighted up");
is( $water_monitor_2->is_on_buzzer_long, 1, "2 LEDs, long buzzer still on" );
is( $water_monitor_2->is_on_buzzer_short, 0, "Short buzzer not on anymore");

$water_monitor_2->current_turbidity(50); # threshold is 180
is( $water_monitor_2->water_dirty, 0, "Turbidity back to normal" );
is( $water_monitor_2->lighted_LED_count, 1, "1 LED lighted up");
is( $water_monitor_2->is_on_buzzer_long, 0, "1 LED, long buzzer is quiet now" );
is( $water_monitor_2->is_on_buzzer_short, 1, "Short buzzer takes over");

$water_monitor_2->current_temperature(23); # range is [20, 25]
is( $water_monitor_2->temperature_is_normal, 1, "Temperature back to normal" );
is( $water_monitor_2->lighted_LED_count, 0, "0 LEDs lighted up");
is( $water_monitor_2->is_on_buzzer_long, 0, "0 LEDs, long buzzer is quiet now" );
is( $water_monitor_2->is_on_buzzer_short, 0, "Short buzzer is quiet, what a peaceful day :)");

done_testing;

# besiyata d'shmaya









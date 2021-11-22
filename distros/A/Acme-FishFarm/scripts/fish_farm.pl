#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm ":all";

my $water_monitor = Acme::FishFarm::WaterConditionMonitor->install;
my $oxygen = Acme::FishFarm::OxygenMaintainer->install( DO_generation_volume => 1.92 );

$water_monitor->add_oxygen_maintainer( $oxygen );

say "Water condition monitor installed...";
say "Oxygen maintainer installed and connected to water condition monitor...";
say "Water condition monitor switched on!";
say "";

# my $first_round = 1; # not applicable for manual input
while ( "fish are swimming happily" ) {
    ### DO
    check_DO( $oxygen, reduce_precision( rand(8) ) );
    say "";
    
    ### pH
    check_pH( $water_monitor, 6.912 );
    #check_pH( $water_monitor, 5.9 );
    say "" ;
    
    ## temperature
    #check_temperature( $water_monitor, 23 );
    check_temperature( $water_monitor, 26 );
    say "";
    
    ## turbidity
    check_turbidity( $water_monitor, 120 );
    #check_turbidity( $water_monitor, 190 );
    say "";
    
    # all LEDs
    render_leds( $water_monitor );
    #if ( $water_monitor->is_on_LED_DO ) {
    #    say "  Low oxygen LED: up";
    #}
    say "";
    
    # buzzers
    render_buzzer( $water_monitor );
    
    sleep(3);
    say "-----------------------------";
}

# besiyata d'shmaya



#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm::WaterConditionMonitor;
use Acme::FishFarm::OxygenMaintainer;

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
    # not applicable for manual input
    #if ( $first_round ) {
    #    $first_round = 0;
    #} else {
    #    consume_oxygen( $oxygen, 1.25 );
    #}

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

# taken directly from oxygen_maintainer.pl

# these 2 subroutines are to be called manually, the check_* only checks the current condition
# must pass in a decimal
sub consume_oxygen {
    my $o2_maintainer = shift;
    my $consumed_oxygen = shift;
    say "$consumed_oxygen mg/L of oxygen consumed...";
    my $o2_remaining = $o2_maintainer->current_DO - $consumed_oxygen;
    $o2_maintainer->current_DO( $o2_remaining );
}

sub reduce_precision {
    my $sensor_reading = shift;
    die "Please pass in a decimal value" if not $sensor_reading =~ /\./;
    $sensor_reading =~ /(\d+\.\d{3})/;
    $1;
}

sub check_DO {
    my ( $oxygen, $current_reading ) = @_;
    my $DO_threshold = $oxygen->DO_threshold;

    $oxygen->current_DO( $current_reading );
    $oxygen->is_low_DO;
    
    say "Current Oxygen Level: ", $current_reading, " mg/L",
        " (low: < ", $DO_threshold, ")";

    if ( $oxygen->is_low_DO ) {
        say "  !! Low oxygen level!";
        # commented ones are not applicable for manual input
            #say "Pumping ", $oxygen->oxygen_generation_volume, " mg/L of oxygen into the water..." ;
            #$oxygen->generate_oxygen;
    } else {
        say "  Oxygen level is normal.";
    }
}

sub check_pH {
    my ( $water_monitor, $current_reading ) = @_;
    my $ph_range = $water_monitor->ph_threshold;
    
    $water_monitor->current_ph( $current_reading );
    $water_monitor->ph_is_normal;
    
    say "Current pH: ", $water_monitor->current_ph, 
        " (normal range: ", $ph_range->[0], "~", $ph_range->[1], ")";

    if ( !$water_monitor->ph_is_normal ) {
        say "  !! Abnormal pH!";
    } else {
        say "  pH is normal."
    }
    
}

sub check_temperature {
    my ( $water_monitor, $current_reading ) = @_;
    my $temperature_range = $water_monitor->temperature_threshold;

    $water_monitor->current_temperature( $current_reading );
    $water_monitor->temperature_is_normal;
    
    say "Current temperature: ", $water_monitor->current_temperature, " C", 
        " (normal range: ", $temperature_range->[0], " C ~ ", $temperature_range->[1], " C)";

    if ( !$water_monitor->temperature_is_normal ) {
        say "  !! Abnormal temperature!";
    } else {
        say "  Temperature is normal."
    }
}

sub check_turbidity {
    my ( $water_monitor, $current_reading ) = @_;
    my $turbidity_threshold = $water_monitor->turbidity_threshold;

    $water_monitor->current_turbidity( $current_reading );
    
    say "Current Turbidity: ", $water_monitor->current_turbidity, " ntu",
        " (dirty: > ", $turbidity_threshold, ")";

    if ( $water_monitor->water_dirty ) {
        say "  !! Water is dirty!";
    } else {
        say "  Water is still clean.";
    } 
}

sub render_leds {
    my $water_monitor = shift;

    # must check condition first! If not it won't work
    $water_monitor->ph_is_normal;
    $water_monitor->temperature_is_normal;
    $water_monitor->lacking_oxygen;    
    $water_monitor->water_dirty;
        
    say "Total LEDs up: ", $water_monitor->lighted_LED_count;

    if ( $water_monitor->is_on_LED_pH ) {
        say "  pH LED: on";
    } else {
        say "  pH LED: off";
    }
    
    if ( $water_monitor->is_on_LED_temperature ) {
        say "  Temperature LED: on";
    } else {
        say "  Temperature LED: off";
    }
    
    if ( $water_monitor->is_on_LED_DO ) {
        say "  Low DO LED: on";
    } else {
        say "  Low DO LED: off";
    }
    
    if ( $water_monitor->is_on_LED_turbidity ) {
        say "  Turbidity LED: on";
    } else {
        say "  Turbidity LED: off";
    }
}

sub render_buzzer {
    my $water_monitor = shift;
    
    #$water_monitor->_tweak_buzzers;
    if ( $water_monitor->is_on_buzzer_long ) {
        say "Long buzzer is on, water condition very critical!";
    } elsif ( $water_monitor->is_on_buzzer_short ) {
        say "Short buzzer is on, water condition is a bit worrying :|";
    } else {
        say "No buzzers on, what a peaceful moment."
    }
}

# besiyata d'shmaya



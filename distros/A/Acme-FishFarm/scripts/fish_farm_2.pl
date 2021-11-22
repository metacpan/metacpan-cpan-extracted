#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm ":all";
use Term::ANSIColor::WithWin32;

my ( $feeder, $oxygen, $water_monitor, $water_level, $water_filter ) = install_all_systems;
show_installation_status();
sleep 1;
show_all_threshold();

$water_level->set_water_level_increase_height(5);

my $feeder_verbose = 1;

print colored(['bold bright_blue'], "Prese <ENTER> to start monitoring your fish farm"); <>;
say "";

while ( "fish are swimming happily" ) {

    # get input for DO, pH, temperature, turbidity, in one go
    print colored(['bold bright_blue'], "Enter current DO level (mg/L): ");
    chomp ( my $current_DO = <>);
    
    print colored(['bold bright_blue'], "Enter current pH value: ");
    chomp ( my $current_pH = <>);
    
    print colored(['bold bright_blue'], "Enter current temperature (C): ");
    chomp ( my $current_temperature = <>);
    
    print colored(['bold bright_blue'], "Enter current turbidity (ntu): ");
    chomp ( my $current_turbidity = <>);

    say colored(['bright_yellow'], "--------------------------------");
    say colored(['bold bright_yellow'], "Water Condition Monitor Report");
    say colored(['bright_yellow'], "--------------------------------");
    
    check_DO( $oxygen, $current_DO ); say "";
    check_pH( $water_monitor, $current_pH ); say "" ;
    check_temperature( $water_monitor, $current_temperature ); say "";
    check_turbidity( $water_monitor, $current_turbidity );
    say colored(['bright_yellow'], "--------------------------------"); say "";
    
    print colored(['bold bright_blue'], "Press <ENTER> to check the LED status"); <>; say "";
    say colored(['bright_yellow'], "------------------------------------");
    say colored(['bold bright_yellow'], "Water Condition Monitor LEDs Status");
    say colored(['bright_yellow'], "------------------------------------");
    render_leds( $water_monitor );
    say colored(['bright_yellow'], "--------------------------------"); say "";
    
    print colored(['bold bright_blue'], "Press <ENTER> to check the buzzer status"); <>; say "";
    say colored(['bright_yellow'], "--------------------------------------");
    say colored(['bold bright_yellow'], "Water Condition Monitor Buzzer Status");
    say colored(['bright_yellow'], "--------------------------------------");
    render_buzzer( $water_monitor );
    say colored(['bright_yellow'], "--------------------------------------"); say "";
    
    print colored(['bold bright_blue'], "Press <ENTER> to check the feeder"); <>; say "";
    say colored(['bright_yellow'], "--------------------------------");
    say colored(['bold bright_yellow'], "Automated Feeder Report");
    say colored(['bright_yellow'], "--------------------------------");
    check_feeder( $feeder, $feeder_verbose );
    say colored(['bright_yellow'], "--------------------------------"); say "";
    
    print colored(['bold bright_blue'], "Enter current waste count (integer): ");
    chomp ( my $current_waste_count = <>);
    say colored(['bright_yellow'], "--------------------------------");
    say colored(['bold bright_yellow'], "Water Filtration Report");
    say colored(['bright_yellow'], "--------------------------------");
    check_water_filter( $water_filter, $current_waste_count );
    say colored(['bright_yellow'], "--------------------------------"); say "";

    print colored(['bold bright_blue'], "Enter current water level (m): ");
    chomp ( my $current_water_level = <>);    
    say colored(['bright_yellow'], "----------------------------------");
    say colored(['bold bright_yellow'], "Water Level Maintainer Report");
    say colored(['bright_yellow'], "-----------------------------------");
    check_water_level( $water_level, $current_water_level );
    say colored(['bright_yellow'], "-----------------------------------"); say "";
    
    say colored(['bold bright_yellow'], "-------------END OF REPORT-----------\n");
    print colored(['bold bright_blue'], "Press <ENTER> to monitor your fish farm again"); <>;
    say "";
}

sub show_installation_status {
    say colored(['bright_yellow'], "Setting up your fish farm..."); sleep(1);
    say colored(['bright_green'], "  Feeder installed and switched on!"); sleep(1);
    say colored(['bright_green'], "  Water level maintiner installed and switched on!"); sleep(1);
    say colored(['bright_green'], "  Water filter installed and switched on!"); sleep(1);
    say colored(['bright_yellow'], "  Setting up water condition monitor..."); sleep(1);
    say colored(['bright_green'], "    Water condition monitor installed!"); sleep(1);
    say colored(['bright_yellow'], "      Oxygen maintainer installed & connected to water condition monitor..."); sleep(1);
    say colored(['bright_green'], "    Water condition monitor switched on!"); sleep(1);
    say colored(['bold bright_blue'], "Your fish farm is ready!");
    say "";
}

sub show_all_threshold {
    my $ph_range = $water_monitor->ph_threshold;
    my $temperature_range = $water_monitor->temperature_threshold;
    
    say colored(['bold bright_magenta'], "Acceptable threshold/range of parameters:");
    say "  Min. DO level: ", $oxygen->DO_threshold, " mg/L";
    say "  pH: ", $ph_range->[0], "~", $ph_range->[1];
    say "  Temperature: ", $temperature_range->[0], "~", $temperature_range->[1], " C";
    say "  Max. Turbidity: ", $water_monitor->turbidity_threshold, " ntu";
    say "  Max. Waste Count: ", $water_filter->waste_count_threshold;
    say "  Min. Water level: ", $water_level->low_water_level_threshold, " m";
    say "";
}

# besiyata d'shmaya



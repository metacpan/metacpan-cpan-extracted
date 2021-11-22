package Acme::FishFarm;

use 5.008;
use strict;
use warnings;
use Carp "croak";

use Acme::FishFarm::Feeder;
use Acme::FishFarm::OxygenMaintainer;
use Acme::FishFarm::WaterConditionMonitor;
use Acme::FishFarm::WaterLevelMaintainer;
use Acme::FishFarm::WaterFiltration;

=head1 NAME

Acme::FishFarm - A Fish Farm with Automated Systems

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

    use 5.010;

    use Acme::FishFarm ":all";

    my $water_monitor = Acme::FishFarm::WaterConditionMonitor->install;
    my $oxygen = Acme::FishFarm::OxygenMaintainer->install( DO_generation_volume => 1.92 );

    $water_monitor->add_oxygen_maintainer( $oxygen );

    say "Water condition monitor installed...";
    say "Oxygen maintainer installed and connected to water condition monitor...";
    say "Water condition monitor switched on!";
    say "";

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
        say "";
        
        # buzzers
        render_buzzer( $water_monitor );
        
        sleep(3);
        say "-----------------------------";
    }
    
=head1 EXPORT

The C<:all> tag can be used to import all the subroutines available in this module.

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    install_all_systems 
    reduce_precision consume_oxygen 
    check_DO check_pH check_temperature check_turbidity check_water_filter check_water_level check_feeder
    render_leds render_buzzer
);
our %EXPORT_TAGS = ( 
    all => [ qw( install_all_systems reduce_precision consume_oxygen check_DO check_pH check_temperature 
                 check_turbidity check_water_filter check_water_level check_feeder render_leds 
                 render_buzzer ) ],
);

=head1 NOTES

Almost all the subroutines in this module will give output. The unit measurements used will be according to the ones mentioned in C<Acme::FishFarm::WaterConditionMonitor>.

=head1 SYSTEM INSTALLATION RELATED SUBROUTINES

=head2 install_all_systems

Installs all the available systems the default way and returns them as a list of C<Acme::FishFarm::*> objects in the following sequence:

  (Feeder, OxygenMaintainer, WaterConditionMonitor, WaterLevelMaintainer, WaterFiltration)

=cut

sub install_all_systems {
    my $feeder = Acme::FishFarm::Feeder->install;
    my $oxygen_maintainer = Acme::FishFarm::OxygenMaintainer->install;
    my $water_monitor = Acme::FishFarm::WaterConditionMonitor->install;
    my $water_level = Acme::FishFarm::WaterLevelMaintainer->install;
    my $water_filter = Acme::FishFarm::WaterFiltration->install;
    
    # remember to connect water oxygem maintainer to water condition monitoring :)
    $water_monitor->add_oxygen_maintainer( $oxygen_maintainer );
    
    ( $feeder, $oxygen_maintainer, $water_monitor, $water_level, $water_filter );
}


=head1 SENSOR READING RELATED SUBROUTINES

=head2 reduce_precision ( $decimal )

Reduces positive or negative C<$decimal> to a 3-decimal value. Make sure to pass in a decimal with more than 3 decimal points.

Returns the reduced precision value.

This subroutine is useful if you are trying to set the current sensor readings randomly using the built-in C<rand> function as you do not want to end up with too many decimals on the screen.

=cut

sub reduce_precision {
    my $sensor_reading = shift;
    croak "Please pass in a decimal value" if not $sensor_reading =~ /\./;
    
    $sensor_reading =~ /(-?\d+\.\d{3})/;
    return $1;
}

=head1 AUTOMATED SYSTEMS RELATED SUBROUTINES

All of the subroutines here will give output.

Take note that there are some systems that can't be connected to the water monitoring system and therefore will not effect the LEDs or buzzers. These systems are:

=over 4

=item * Acme::FishFarm::Feeder

=item * Acme::FishFarm::WaterFiltration

=item * Acme::FishFarm::WaterLevelMaintainer

=back

=head2 consume_oxygen ( $oxygen_maintainer, $consumed_oxygen )

This will cause the oxygen level (DO level) of the C<Acme::FishFarm::OxygenMaintainer> to reduce by C<$consumed_oxygen mg/L>

Returns 1 upon success.
=cut

sub consume_oxygen {
    my $o2_maintainer = shift;
    my $consumed_oxygen = shift;
    print "$consumed_oxygen mg/L of oxygen consumed...\n";
    my $o2_remaining = $o2_maintainer->current_DO - $consumed_oxygen;
    $o2_maintainer->current_DO( $o2_remaining );
    1;
}

=head2 check_DO ( $oxygen_maintainer, $current_DO_reading )

This checks and outputs the condition of the current DO level.

Take note that this process will trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.
=cut

sub check_DO {
    my ( $oxygen, $current_reading ) = @_;
    my $DO_threshold = $oxygen->DO_threshold;

    $oxygen->current_DO( $current_reading );
    $oxygen->is_low_DO;
    
    print "Current Oxygen Level: ", $current_reading, " mg/L",
        " (low: < ", $DO_threshold, ")\n";

    if ( $oxygen->is_low_DO ) {
        print "  !! Low oxygen level!\n";
    } else {
        print "  Oxygen level is normal.\n";
    }
    1;
}

=head2 check_pH ( $water_monitor, $current_ph_reading )

This checks and outputs the condition of the current pH value.

Take note that this process will trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_pH {
    my ( $water_monitor, $current_reading ) = @_;
    my $ph_range = $water_monitor->ph_threshold;
    
    $water_monitor->current_ph( $current_reading );
    $water_monitor->ph_is_normal;
    
    print "Current pH: ", $water_monitor->current_ph, 
        " (normal range: ", $ph_range->[0], "~", $ph_range->[1], ")\n";

    if ( !$water_monitor->ph_is_normal ) {
        print "  !! Abnormal pH!\n";
    } else {
        print "  pH is normal.\n";
    }
    1;
}

=head2 check_temperature ( $water_monitor, $current_temperature_reading )

This checks and outputs the condition of the current temperature.

Take note that this process will trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_temperature {
    my ( $water_monitor, $current_reading ) = @_;
    my $temperature_range = $water_monitor->temperature_threshold;

    $water_monitor->current_temperature( $current_reading );
    $water_monitor->temperature_is_normal;
    
    print "Current temperature: ", $water_monitor->current_temperature, " C", 
        " (normal range: ", $temperature_range->[0], " C ~ ", $temperature_range->[1], " C)\n";

    if ( !$water_monitor->temperature_is_normal ) {
        print "  !! Abnormal temperature!\n";
    } else {
        print "  Temperature is normal.\n";
    }
    1;
}

=head2 check_turbidity ( $water_monitor, $current_turbidity_reading )

This checks and outputs the condition of the current temperature.

Take note that this process will trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_turbidity {
    my ( $water_monitor, $current_reading ) = @_;
    my $turbidity_threshold = $water_monitor->turbidity_threshold;

    $water_monitor->current_turbidity( $current_reading );
    
    print "Current Turbidity: ", $water_monitor->current_turbidity, " ntu",
        " (dirty: > ", $turbidity_threshold, ")\n";

    if ( $water_monitor->water_dirty ) {
        print "  !! Water is dirty!\n";
    } else {
        print "  Water is still clean.\n";
    }
    1;
}


=head2 check_water_filter ( $water_filter, $current_waste_count, $reduce_waste_by )

This checks, performs necessary actions and outputs the condition of the current waste count in the filtering cylinder.

Take note that this process B<DOES NOT> trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_water_filter {
    my $water_filter = shift;
    my $current_reading = shift;
    my $reduce_waste_by = shift || $water_filter->reduce_waste_count_by;
    my $waste_threshold = $water_filter->waste_count_threshold;
    
    $water_filter->current_waste_count( $current_reading );
    print "Waste Count to Reduce: ", $water_filter->reduce_waste_count_by, "\n";
    print "Current Waste Count: ", $current_reading, " (high: >= ", $waste_threshold, ")\n";

    if ( $water_filter->is_cylinder_dirty ) {
        print "  !! Filtering cylinder is dirty!\n";
        $water_filter->turn_on_spatulas;
        print "  Cleaning spatulas turned on.\n";
        $water_filter->clean_cylinder( $reduce_waste_by );
        print "  Cleaning the cylinder...Done!\n";
        print "Current waste count: ", $water_filter->current_waste_count, "\n";
    } else {
        print "  Filtering cylinder is still clean.\n";
    }
    1;
}

=head2 check_water_level ( $water_level_maintainer, $current_water_level )

This checks, performs necessary actions and outputs the condition of the current waste count in the filtering cylinder.

Take note that this process B<DOES NOT> trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_water_level {
    my $water_level = shift;
    my $current_reading = shift;
    my $height_increase = $water_level->water_level_increase_height; # for output
    my $water_level_threshold = $water_level->low_water_level_threshold;
    
    $water_level->current_water_level( $current_reading ); # input by user
    print "Current Water Level: ", $current_reading, " m (low: < ", $water_level_threshold, " m)\n";

    if ( $water_level->is_low_water_level ) {
        print "  !! Water level is low!\n";
        $water_level->pump_water_in;
        print "  Pumping in ", $height_increase, " m of water...\n";
        print "Current Water Level: ", $water_level->current_water_level, " m\n";
    } else {
        print "  Water level is still normal.\n";
    }
    1;
}

=head2 check_feeder ( $feeder, $verbose )

This checks, performs necessary actions and outputs the condition of the feeder. Each call will tick the clock inside the feeder. See C<Acme::FishFarm::Feeder> for more info.

If the food tank is empty, it will be filled to the default. So if you want to fill a different amount, please set the amount before hand. See C<Acme::FishFarm::Feeder>.

Setting C<$verbose> to 1 will give more output about the empty food tank.

Take note that this process B<DOES NOT> trigger the LED and buzzer if abnormal condition is present.

Returns 1 upon success.

=cut

sub check_feeder {
    my ( $feeder, $verbose ) = @_;
    if ( $feeder->timer_is_up ) {
        print "Timer is up, time to feed the fish!\n";
        
        if ( $verbose) {
            $feeder->feed_fish( verbose => 1 );        
        } else {
            $feeder->feed_fish;
        }
        print "  Feeding ", $feeder->feeding_volume, " cm^3 of fish food to the fish...\n";
        
    } else {
        print $feeder->time_remaining, " hours left until it's time to feed the fish.\n";
    }
    
    if ( $feeder->food_remaining <= 0  ) {
        print "  !! Food tank empty!\n";
        $feeder->refill; # default back to 500 cm^3
        print "  Refilled food tank back to ", $feeder->food_tank_capacity, " cm^3.\n";
    }

    print "  Food Remaining: ", $feeder->food_remaining, "cm^3.\n";
    
    $feeder->tick_clock;
    1;
}

=head2 render_leds ( $water_monitor )

Outputs which LEDs are lighted up. Returns 1 upon success.

Currently this subroutine only shows the LEDs present in the  C<Acme::FishFarm::WaterConditionMonitor> object. See that module for more details about the available LEDs.

More LEDs will be available in the future.

=cut

sub render_leds {
    my $water_monitor = shift;

    # must check condition first! If not it won't work
        # this process will update the LEDs status
    $water_monitor->ph_is_normal;
    $water_monitor->temperature_is_normal;
    $water_monitor->lacking_oxygen;    
    $water_monitor->water_dirty;
        
    print "Total LEDs up: ", $water_monitor->lighted_LED_count, "\n";

    if ( $water_monitor->is_on_LED_pH ) {
        print "  pH LED: on\n";
    } else {
        print "  pH LED: off\n";
    }
    
    if ( $water_monitor->is_on_LED_temperature ) {
        print "  Temperature LED: on\n";
    } else {
        print "  Temperature LED: off\n";
    }
    
    if ( $water_monitor->is_on_LED_DO ) {
        print "  Low DO LED: on\n";
    } else {
        print "  Low DO LED: off\n";
    }
    
    if ( $water_monitor->is_on_LED_turbidity ) {
        print "  Turbidity LED: on\n";
    } else {
        print "  Turbidity LED: off\n";
    }
    1;
}

=head2 render_buzzer ( $water_monitor )

Outputs which buzzer is buzzing. Returns 1 upon success.

See C<Acme::FishFarm::WaterConditionMonitor> for details on how the short and long buzzers are switched on and off.

=cut

sub render_buzzer {
    my $water_monitor = shift;
    
    #$water_monitor->_tweak_buzzers;
    if ( $water_monitor->is_on_buzzer_long ) {
        print "Long buzzer is on, water condition very critical!\n";
    } elsif ( $water_monitor->is_on_buzzer_short ) {
        print "Short buzzer is on, water condition is a bit worrying :|\n";
    } else {
        print "No buzzers on, what a peaceful moment.\n";
    }
    1;
}


=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-fishfarm at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-FishFarm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-FishFarm>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-FishFarm>

=item * Search CPAN

L<https://metacpan.org/release/Acme-FishFarm>

=back


=head1 ACKNOWLEDGEMENTS

Besiyata d'shmaya

=head1 SEE ALSO

    Acme::FishFarm::Feeder

    Acme::FishFarm::OxygenMaintainer

    Acme::FishFarm::WaterConditionMonitor

    Acme::FishFarm::WaterFiltration

    Acme::FishFarm::::WaterLevelMaintainer

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::FishFarm

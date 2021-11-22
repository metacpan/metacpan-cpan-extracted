package Acme::FishFarm::WaterConditionMonitor;

use 5.006;
use strict;
use warnings;
use Carp "croak";

=head1 NAME

Acme::FishFarm::WaterConditionMonitor - Water Condition Monitor for Acme::FishFarm

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

    use 5.010;

    use Acme::FishFarm::WaterConditionMonitor;
    use Acme::FishFarm::OxygenMaintainer;

    my $water_monitor = Acme::FishFarm::WaterConditionMonitor->install;
    my $oxygen = Acme::FishFarm::OxygenMaintainer->install( DO_generation_volume => 1.92 );

    $water_monitor->add_oxygen_maintainer( $oxygen );
    
    # always check water conditions before checking LEDs and buzzers
    # also, these four method will return 1 or 0, upon calling them, the status of LEDs and buzzers will also be updated
    $water_monitor->ph_is_normal;
    $water_monitor->temperature_is_normal;
    $water_monitor->lacking_oxygen;
    $water_monitor->water_dirty;
    
    if ( $water_monitor->is_on_LED_DO ) {
        # do something, same goes to the rest of the LEDs
    }

    if ( $water_monitor->is_on_buzzer_short ) {
        # do something
    } elsif ( $water_monitor->is_on_buzzer_long ) {
        # do something
    }

=head1 EXPORT

None

=head1 NOTES

Some of the methods in this module can be confusing expecially when it comes to checking abnormal water conditions.

B<Please always always always check the water condition before checking the LEDs and buzzers status.>

C<Acme::FishFarm> contains subroutines to check all the abnormal water conditions to ease this job.

=head1 CREATION RELATED SUBROUTINES/METHODS

Only 3 sensors are built-in. However, there is a 4th socket for the oxygen maintainer. For this socket, you'll need to manuall connect an Acme::FishFarm::OxygenMaintainer object by calling the C<add_oxygen_maintainer> method.

More sockets might be available in the future.

=head2 install ( %sensors )

Installs a water condition monitoring system.

The C<%sensors> included are:

=over 4

=item pH

Optional. The default threshold range is C<[6.5, 7.5]> and the default pH is C<7.0>.

This will set the threshold value of the water pH. Please pass in an array reference to this key
in the form of C<[min_pH, max_pH]>

The values are in the range of C<1-14>. However, this range is not checked for incorrect values.

=item temperature

Optional. The default threshold range is C<[20, 25]> degree celcius and the default temprature is C<25>.

This will set the threshold value of the water temperature. Please pass in an array reference to this key
in the form of C<[min_temperature, max_temperature]>

The ranges of values are between C<0> and C<50> degree B<celcius>. However, this range is not checked for incorrect values. The unit C<celcius> is just a unit, it doesn't show up if you call any of it's related getters.

=item turbidity

Optional. The default threshold is C<180 ntu> and the default turbidity is set to C<10 ntu>.

This will set the threshold of the turbidity of the water.

The range of values are between C<0 ntu> and C<300 ntu>. However, this range is not checked for incorrect values. The unit C<ntu> is just a unit, it doesn't show up if you call any of it's related getters.

=back

=cut

sub install {
    my $class = shift;
    my %sensors = @_;
    
    if ( not $sensors{pH} ) {
        $sensors{pH_range} = [6.5, 7.5];
        $sensors{current_pH} = 7.0;
        $sensors{pH_LED_on} = 0;
    }
    
    if ( not $sensors{temperature} ) {
        $sensors{temperature_range} = [20, 25];
        $sensors{current_temperature} = 23;
        $sensors{temperature_LED_on} = 0;
    }
    
    if ( not $sensors{turbidity} ) {
        $sensors{turbidity_threshold} = 180;
        $sensors{current_turbidity} = 10;
        $sensors{turbidity_LED_on} = 0;
    }
    
    # low DO led, use Acme::FishFarm::OxygenMaintainer to determine
    $sensors{DO_LED_on} = 0;
    
    $sensors{lighted_LED_count} = 0;
    $sensors{short_buzzer_on} = 0;
    $sensors{long_buzzer_on} = 0;
    
    bless \%sensors, "Acme::FishFarm::WaterConditionMonitor";
}


=head2 add_oxygen_maintainer ( $oxygen_maintainer )

Connects the oxygen maintainer ie C<Acme::FishFarm::OxygenMaintainer> system to this monitoring system.

For now, this module can only check if the oxygen is lacking or not. This module contains a user friendly method compared to the standard terminology used in the C<Acme::FishFarm::OxygenMaintainer> module. Other user friendly methods will be added in the future.

=cut

sub add_oxygen_maintainer {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( ref( my $oxygen_maintainer = shift ) ne "Acme::FishFarm::OxygenMaintainer") {
        croak "Please pass in an Acme::FishFarm::OxygenMaintainer object!";
    } else {
        $self->{oxygen_maintainer} = $oxygen_maintainer;
    }
}

=head1 WATER CONDITIONS RELATED SUBROUTINES/METHODS

=head2 current_ph ( $new_ph )

Sets / returns the current pH of the water.

C<$new_pH> is optional. If present, the current pH will be set to C<$new_ph>. Otherwise, returns the current pH reading.

=cut

sub current_ph {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( @_ ) {
        $self->{current_pH} = shift;
    } else {
        $self->{current_pH};
    }
}

=head2 ph_threshold

Returns the pH threshold as an array ref.

=cut

sub ph_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{pH_range};
}

=head2 set_ph_threshold ( $ph_value )

Sets the pH threshold.

=cut

sub set_ph_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    my $new_ph_range_ref = shift;
    croak "Please supply an array ref to set new pH range" if ref( $new_ph_range_ref ) ne ref( [] );
    $self->{pH_range} = $new_ph_range_ref;
}

=head2 ph_is_normal

Returns true if the current pH is within the set range of threshold.

The pH LED will light up and a short buzzer will be turned on if B<only> the pH is not normal.

Don't worry about the long buzzer as it will be taken care of behind the scene.

=cut

sub ph_is_normal {
    ref( my $self = shift ) or croak "Please use this the OO way";

    _tweak_buzzers( $self );
    
    if ( $self->{current_pH} >= $self->{pH_range}[0] and $self->{current_pH} <= $self->{pH_range}[1] ) {
    
        # if still on, switch it off, it's normal now
        if ( $self->is_on_LED_pH ) {
            $self->{pH_LED_on} = 0;
        }
        
        return 1;
    } else {
        $self->{pH_LED_on} = 1;
        return 0;
    }
}

=head2 current_temperature ( $new_temperature )

Sets / returns the current temperature of the water.

C<$new_temperature> is optional. If present, the current temperature will be set to C<$new_temperature>. Otherwise, returns the current temperature reading.

=cut

sub current_temperature {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    if ( @_ ) {
        $self->{current_temperature} = shift;
    } else {
        $self->{current_temperature};
    }
    
}

=head2 temperature_threshold

Returns the acceptable temperature range as an array ref.

=cut

sub temperature_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{temperature_range};
}

=head2 set_temperature_threshold ( $new_temperature )

Sets the water temperature threshold.

=cut

sub set_temperature_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    my $new_temperature_range_ref = shift;
    croak "Please supply an array ref to set new temperature range" 
        if ref( $new_temperature_range_ref ) ne ref( [] );
    $self->{temperature_range} = $new_temperature_range_ref;
}

=head2 temperature_is_normal

Returns true if the current temperature is within the set range of threshold.

The temperature LED will light up and a short buzzer will be turned on if B<only> the temperature is not normal.

Don't worry about the long buzzer as it will be taken care of behind the scene.

=cut

sub temperature_is_normal {
    ref( my $self = shift ) or croak "Please use this the OO way";

    _tweak_buzzers( $self );
    
    if ( $self->{current_temperature} >= $self->{temperature_range}[0] 
        and $self->{current_temperature} <= $self->{temperature_range}[1] ) {
        
        # if still on, switch it off, it's normal now
        if ( $self->is_on_LED_temperature ) {
            $self->{temperature_LED_on} = 0;
        }
        
        return 1;
    } else {
        $self->{temperature_LED_on} = 1;
        return 0;
    }
}

=head2 lacking_oxygen

Returns true if the current DO content is lower than the threshold.

=cut

sub lacking_oxygen {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    _tweak_buzzers( $self );
    
    if ( $self->{oxygen_maintainer}->is_low_DO) {
        $self->{DO_LED_on} = 1;
        return 1;
    } else {
        # if still on, switch it off, it's normal now
        if ( $self->is_on_LED_DO ) {
            $self->{DO_LED_on} = 0;
        }
        
        return 0;
    }
    
}

=head2 current_turbidity ( $new_turbidity )

Sets / returns the current turbidity of the water.

C<$new_turbidity> is optional. If present, the current turbidity will be set to C<$new_turbidity>. Otherwise, returns the current turbidity reading.

=cut

sub current_turbidity {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    if ( @_ ) {
        $self->{current_turbidity} = shift;
    } else {
        $self->{current_turbidity};
    }
    
}

=head2 turbidity_threshold

Returns the turbidity threshold.

=cut

sub turbidity_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{turbidity_threshold};
}

=head2 set_turbidity_threshold ( $new_turbidity_threshold )

Sets the turbidity threshold to C<$new_turbidity_threshold>.

=cut

sub set_turbidity_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";

    $self->{turbidity_threshold} = shift;
}

=head2 water_dirty

Returns true if the current turbidity is highter then the threshold.

The turbidity LED will light up and a short buzzer will be turned on if B<only> the turbidity is not normal.

Don't worry about the long buzzer as it will be taken care of behind the scene.

=cut

sub water_dirty {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    _tweak_buzzers( $self );
    
    if ( $self->{current_turbidity} >= $self->{turbidity_threshold} ) {
        
        $self->{turbidity_LED_on} = 1;
        return 1;
    } else {

        # if still on, switch it off, it's normal now
        if ( $self->is_on_LED_turbidity ) {
            $self->{turbidity_LED_on} = 0;
        }
        
        return 0;
    }
}


# these 2 should be wrappers of something in the future
=head1 BUZZER RELATED SUBROUTINES/METHODS

=head2 is_on_buzzer_short

Returns true if the short buzzer is turned on.

A short buzzer will buzz ie turned on if there is 1 abnormal condition. If more than 1 abnormal conditions are present, the long buzzer will be turned on and this short buzzer will be turned off so that it's not too noisy :)

=cut

sub is_on_buzzer_short {
    ref( my $self = shift ) or croak "Please use this the OO way";
    _tweak_buzzers( $self );
    return $self->{short_buzzer_on};
}


=head2 is_on_buzzer_long

Returns true if the long buzzer is turned on and also turns off the short buzzer to reduce noise.

=cut

sub is_on_buzzer_long {
    ref( my $self = shift ) or croak "Please use this the OO way";
    _tweak_buzzers( $self );
    return $self->{long_buzzer_on};
}

=head1 Private Methods for Buzzers

=over 4

=item &_tweak_buzzers ( $self )

Tweak the buzzers. It's either the short buzzer or the long buzzer switched on only. This subroutine will be called whenever a condition checking method is called in order to update the buzzers status.

=back

=cut

sub _tweak_buzzers {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    # short buzzer
    if ( $self->lighted_LED_count == 1 ) {
        $self->{short_buzzer_on} = 1;
        $self->{long_buzzer_on} = 0;
        
    # long buzzer
    } elsif ( $self->lighted_LED_count > 1 ) {
        $self->{short_buzzer_on} = 0;
        $self->{long_buzzer_on} = 1;
        
    # no buzzer
    } elsif ( $self->lighted_LED_count == 0 ) {
        $self->{short_buzzer_on} = 0;
        $self->{long_buzzer_on} = 0;
        
    # somthing's wrong
    } else {
        die "Something's wrong with LED count";
    }
}

=head1 LED LIGHTS RELATED SUBROUTINES/METHODS

An LED is lighted up if the corresponding parameter is in abnormal state.

=head2 on_LED_pH

Lights up the LED for pH sensor, indicating abnormal pH.

=head2 is_on_LED_pH

Returns true if the LED of pH is lighted up.

=cut

sub on_LED_pH {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{pH_LED_on} = 1;
}

sub is_on_LED_pH {
    ref( my $self = shift ) or croak "Please use this the OO way";
    return $self->{pH_LED_on};
}

=head2 on_LED_temperature

Lights up the LED for temperature sensor, indicating abnormal water temperature.

=head2 is_on_LED_temperature

Returns true if the LED of temperature is lighted up.

=cut

sub on_LED_temperature {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{temperature_LED_on} = 1;
}

sub is_on_LED_temperature {
    ref( my $self = shift ) or croak "Please use this the OO way";
    return $self->{temperature_LED_on};
}

=head2 on_LED_DO

Lights up the LED for dissolved oxygen sensor, indicating low DO content. You fish might die :)

=head2 is_on_LED_DO

Returns true if the LED of DO is lighted up.

=cut

sub on_LED_DO {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{DO_LED_on} = 1;
}

sub is_on_LED_DO {
    ref( my $self = shift ) or croak "Please use this the OO way";
    return $self->{DO_LED_on};
}

=head2 on_LED_turbidity

Light up the LED for turbidity sensor, indicating high level of waste etc. Fish might die :)

=head2 is_on_LED_turbidity

Returns true if the LED of DO is lighted up.

=cut

sub on_LED_turbidity {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{turbidity_LED_on} = 1;
}

sub is_on_LED_turbidity {
    ref( my $self = shift ) or croak "Please use this the OO way";
    return $self->{turbidity_LED_on};
}

=head2 lighted_LED_count

Returns the number of LEDs lighted up currently

=cut

sub lighted_LED_count {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    my $total_led = 0;
    $total_led++ if $self->{pH_LED_on};
    $total_led++ if $self->{temperature_LED_on};
    $total_led++ if $self->{DO_LED_on};
    $total_led++ if $self->{turbidity_LED_on};
    
    return $total_led;
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm::WaterConditionMonitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/.>

=item * Search CPAN

L<https://metacpan.org/release/.>

=back


=head1 ACKNOWLEDGEMENTS

Besiyata d'shmaya

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::FishFarm::WaterConditionMonitor

package Acme::FishFarm::Feeder;

use 5.008;
use strict;
use warnings;

use Carp "croak";

=head1 NAME

Acme::FishFarm::Feeder - Automated Feeder for Acme::FishFarm

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

    use 5.010;
    use Acme::FishFarm::Feeder;

    my $feeder = Acme::FishFarm::Feeder->install( timer => 3, feeding_volume => 150 );

    say "Feeder installed and switched on!";
    say "";

    while ( "fish are living happilly" ) {

        if ( $feeder->timer_is_up ) {
            say "\nTimer is up, time to feed the fish!";
            say "Feeding ", $feeder->feeding_volume, " cm^3 of fish food to the fish...";
            
            $feeder->feed_fish;
            
            say $feeder->food_remaining, " cm^3 of fish food remaining in the tank.\n";
        }
        
        if ( $feeder->food_remaining <= 0  ) {
            $feeder->refill; # default back to 500 cm^3
            say "Refilled food tank back to ", $feeder->food_tank_capacity, " cm^3.\n";
        }
        
        say $feeder->time_remaining, " hours left until it's time to feed the fish.";

        sleep(1);
        $feeder->tick_clock;
    }

    say "";
    say "Feeder was switched off, please remeber to feed your fish on time :)";

=head1 EXPORT

None

=head1 CREATION RELATED METHODS

=head2 install ( %options )

Installs an automated fish feeder.

The following are available for C<%options>:

=over 4

=item * timer

The default is C<8>.

This is used as a threshold to identify that the time is up to feed the fish or not.

The clock will be set to this value for countdown.

=item * feeding_volume

The default is C<50 cm^3>.

=item * food_tank_capacity

The maximum volume of fish food. Default is C<500 cm^3>.

=item * current_food_amount

The initial amount of food to be filled into the food tank. Default is max ie C<500 cm^3>.

=back

=cut

sub install {
    my $class = shift;
    my %options = @_;
    
    # value of 0 should not work
    if ( not $options{timer} ) {
        $options{timer} = 8; # this is used as a reference only
    }
    
    # when clock is a multiple of timer, then feed fish
    $options{clock} = 0; # this is the actual one that will keep changing
    
    if ( not $options{feeding_volume} ) {
        $options{feeding_volume} = 50;
    }
    
    if ( not $options{food_tank_capacity} ) {
        $options{food_tank_capacity} = 500;
    }
    
    if ( not $options{current_food_amount} ) {
        $options{current_food_amount} = $options{food_tank_capacity};
    }
    
    $options{first_usage} = 1; # make sure the feeder doesn't say timer is up as soon as it is switched on
    
    bless \%options, $class;
}



=head1 TIMER RELATED SUBROUTINES/METHODS

=head2 get_timer

Returns the timer threshold of the feeder.

=cut

sub get_timer {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{timer};
}

=head2 set_timer ( $time )

Sets the new timer threshold of the feeder.

Setting this timer will not affect the clock within the feeder.

=cut

sub set_timer {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{timer} = shift;
}


=head2 timer_is_up

Check if the timer is up. If timer is up, please remember to feed your fish. See C<feed_fish> for more info.

=cut

sub timer_is_up {
    ref (my $self = shift) or croak "Please use this the OO way";
    
    # skip the first round, 0 % n is always 0 and the feeder might think it's time to feed the fish as soon as it's switched on
    if ( $self->{first_usage} ) {
        $self->{first_usage} = 0;
        return 0;
    }
    
    if ( $self->{clock} % $self->{timer} == 0 ) {
        # reset clock to 0 and return true
        $self->{clock} = 0; # just in case the clock runs for too long
        1;
    } else {
        0;
    }
}

=head2 time_remaining

Returns the time remaining to feed the fish.

This method might not be really useful, but anyway :)

=cut

sub time_remaining {
    ref (my $self = shift) or croak "Please use this the OO way";
    $self->{timer} - $self->{clock};
}

=head2 tick_clock ( $custom_tick )

C<$custom_tick> is optional and the default is C<1>.

This will cause the timer of the feeder to increase by C<1> (default) or by C<$custom_tick>.

=cut

sub tick_clock {
    ref (my $self = shift) or croak "Please use this the OO way";
    ++$self->{clock};
}


=head1 FOOD TANK RELATED SUBROUTINE/METHODS

=head2 food_tank_capacity

Returns the current food tank capacity.

=cut

sub food_tank_capacity {
    ref (my $self = shift) or croak "Please use this the OO way";
    $self->{food_tank_capacity};
}

=head2 set_food_tank_capacity ( $new_capacity )

Set the new food tank capacity to C<$new_capacity>.

=cut

sub set_food_tank_capacity {
    no warnings "numeric";
    ref (my $self = shift) or croak "Please use this the OO way";
    my $new_capacity = int (shift) || return;
    $self->{food_tank_capacity} = $new_capacity;
}

=head2 food_remaining

Returns the remaining amount of food left.

=cut

sub food_remaining {
    ref (my $self = shift) or croak "Please use this the OO way";
    $self->{current_food_amount};
}

=head1 FEEDING RELATED SUBROUTINES/METHODS

=head2 feed_fish ( %options )

Feeds the fish.

Take note that this will feed the fish no matter what. So it's up to you to make sure that you check if the 
feeder timer is really up or not before calling this method. See C<timer_is_up> for more info.

C<%options> supports the following key:

=over 4

=item * verbose

Setting this to a true value will give output about the feeder's situation when feeding the fish.

=back

=cut

sub feed_fish {
    ref (my $self = shift) or croak "Please use this the OO way";
    my %options = @_;
    if ( $self->{current_food_amount} - $self->{feeding_volume} <= 0 ) {
        if ( $options{verbose} ) {
            print "Your feeder has run out of food, please refill as soon as possible.\n";
            print "Only managed to feed $self->{current_food_amount} cm^3 of food to the fish.\n";
        }
        $self->{current_food_amount} = 0;
    } else {
        $self->{current_food_amount} = $self->{current_food_amount} - $self->{feeding_volume};
    }
}

=head2 set_feeding_volume ( $volume )

Sets the fish food feeding volume.

C<$volume> must be a positive number. No error checking is done for this yet.

=cut

sub set_feeding_volume {
    ref (my $self = shift) or croak "Please use this the OO way";
    my $volume = shift or croak "Please specify feeding volume";
    $self->{feeding_volume} = $volume;
}

=head2 feeding_volume

Returns the amount of food to feed the fish each time the C<feed_fish> method is called.

=cut

sub feeding_volume {
    ref (my $self = shift) or croak "Please use this the OO way";
    $self->{feeding_volume};
}

=head2 refill ( $volume )

Refills the fish food tank B<TO> C<$volume>.

If C<$volume> is not specified, the food tank will be filled to max.

If C<$volume> is a strange value, it will be ignored and filled to max.

=cut

sub refill {
    no warnings "numeric";
    ref (my $self = shift) or croak "Please use this the OO way";

    my $volume = shift || $self->{food_tank_capacity};
    return if not int($volume);
    
    if ( $volume > $self->{food_tank_capacity} ) {
        $self->{current_food_amount} = $self->{food_tank_capacity};
    } else {
        $self->{current_food_amount} = $volume;
    }
    
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm::Feeder


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

=head1 SEE ALSO

    Acme::FishFarm

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::FishFarm::Feeder

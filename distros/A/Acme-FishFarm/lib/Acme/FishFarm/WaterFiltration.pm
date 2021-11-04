package Acme::FishFarm::WaterFiltration;

use 5.006;
use strict;
use warnings;
use Carp "croak";

=head1 NAME

Acme::FishFarm::WaterFiltration - Water Filter for Acme::FishFarm

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

    use Acme::FishFarm::WaterFiltration;
    # missing stuff will be added in the next release

=head1 EXPORT

None

=head1 DESCRIPTION

This module assumes a cool water filter with a filtering cylinder constantly filtering water in 
the tank. It has inlet, outlet and a drainage valves. The drainage valve is only opened when the
cleaners are switched on automatically to remove waste from the cylinder. To be honest, those cleaners look more like spatulas to me :)

This feature is based on the water filter found L<here|https://www.filternox.com/filters/spt-wbv-mr/>

=head1 CREATION SUBROUTINES/METHODS

=head2 install ( %options )

Installs a cool water filtration system.

The following are avaiable for C<%options>:

=over 4

=item current_waste_count

The current waste count in the cylinder. Default is C<0>.

=item waste_threshold

Default value is C<75>.

Sets the waste treshold.

This is the maximum limit of waste in the cylinder. When this count is hit, it will turn on the cleaners / spatulas or whatever it's called :).

=item reduce_waste_count_by

Default is 10.

The amount of waste to remove from the cylinder / filter each time the cleaning process is called.

=back

=cut

sub install {
    my $class = shift;
    my %options = @_;
    
    if ( not $options{current_waste_count} ) {
        $options{current_waste_count} = 0;
    }
    
    if ( not $options{waste_threshold} ) {
        $options{waste_threshold} = 75;
    }
    
    $options{is_on_spatulas} = 0;
    $options{reduce_waste_count_by} = 10;
    
    bless \%options, "Acme::FishFarm::WaterFiltration";
}


=head1 WASTE LEVEL DETECTING SUBROUTINES/METHODS

=head2 current_waste_count ( $new_waste_count )

Sets / returns the current waste count inside the cylinder.

C<$new_waste_count> is optional. If present, the current waste count will be set to C<$new_waste_count>. Otherwise, returns the current waste count.

=cut

sub current_waste_count {
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    if ( @_ ) {
        $self->{current_waste_count} = shift;
    } else {
        $self->{current_waste_count};
    }
}

=head2 waste_count_threshold

Returns the waste count threshold.

=cut

sub waste_count_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{waste_threshold};
}

=head2 set_waste_count_threshold

Sets the waste count threshold.

=cut

sub set_waste_count_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{waste_threshold} = shift;
}

=head2 reduce_waste_count_by

Returns the amount of waste to be reduce each time the cleaning process is called.

=cut

sub reduce_waste_count_by {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{reduce_waste_count_by};
}

=head2 set_waste_count_to_reduce ( $new_count )

Sets the waste count reduction value to C<$new_count>.

=cut

sub set_waste_count_to_reduce {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{reduce_waste_count_by} = shift;
}

=head2 is_filter_layer_dirty

Synonym for C<is_cylinder_dirty>. See next method.

=head2 is_cylinder_dirty

Returns C<1> if the filtering cylinder is dirty ie current waste count hits the waste count threshold. Returns C<0> otherwise.

Remember to clean your cylinder ie. filter layer as soon as possible.

=cut

sub is_filter_layer_dirty {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->is_cylinder_dirty;
}

sub is_cylinder_dirty {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( $self->{current_waste_count} >= $self->{waste_threshold} ) {
        return 1;
    } else {
        return 0;
    }
}

=head1 CLEANING RELATED SUBROUTINES/METHODS

=head2 clean_filter_layer

Synonym for C<is_cylinder_dirty>. See next method.

=cut

sub clean_filter_layer {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->clean_cylinder(@_);
}

=head2 clean_cylinder ( $reduce_waste_by )

Cleans the filter layer in the cylinder.

C<$reduce_waste_by> is optional. If present, it will reduce waste by that specific value. Otherwise, it cleans the cylinder completly in one shot ie waste count will be C<0>.

If C<$reduce_waste_by> is a negative value, it will be turned into a positive value with the same magnitude.

Make sure that you turn on your spatula, if not this process will not do anything :)

=cut

sub clean_cylinder {
    no warnings "numeric";
    ref( my $self = shift ) or croak "Please use this the OO way";
    
    my $reduce_waste_by;
    if (@_) {
        my $reduce = shift;
        if ( $reduce < 0 ) {
            $reduce_waste_by = abs($reduce);
            # futhre error checking is done in Acme::FishFarm::check_water_filter
        } else {
            $reduce_waste_by = $reduce;
        }
    } else {
        $reduce_waste_by = 0;
    }
    
    if ( $self->{is_on_spatulas} ) {
        
        if ( $reduce_waste_by ) {
            #reduce based on user input
            if ( $self->{current_waste_count} > $reduce_waste_by ) {
                $self->{current_waste_count} -= $reduce_waste_by;
            } else {
                # $reduce_waste_by not specified
                $self->{current_waste_count} = 0;
            }
        } else {
            $self->{current_waste_count} = 0;
        }
        
    } else {
        return;
    }
}

=head2 turn_on_spatulas

Activates the cleaning mechanism ie the spatulas :)

Take note that turning on the spatulas does not clean the cylinder. You need to do it explicitly. See C<clean_cylinder> method for more info :)

=head2 turn_off_spatulas

Deactivates the cleaning mechanism ie the spatulas :)

See C<clean_cylinder> method for more info :)

=head2 is_on_spatulas

Returns C<1> if the spatula are turned on. The spatula will not clean the cylinder until you explicitly tell the system to do so. See C<clean_cylinder> for more info.

=cut

sub turn_on_spatulas {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{is_on_spatulas} = 1;
}

sub turn_off_spatulas {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{is_on_spatulas} = 0;
}

sub is_on_spatulas {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{is_on_spatulas};
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm::WaterFiltration


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

1; # End of Acme::FishFarm::WaterFiltration

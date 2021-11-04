package Acme::FishFarm::OxygenMaintainer;

use 5.006;
use strict;
use warnings;
use Carp "croak";

=head1 NAME

Acme::FishFarm::OxygenMaintainer - Oxygen Maintainer for Acme::FishFarm

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

    use Acme::FishFarm::OxygenMaintainer;
    # missing stuff will be added in the next release

=head1 EXPORT

None

=head1 CREATION RELATED SUBROUTINES/METHODS

=head2 install ( %options )

Installs an oxygen maintainer system.

The supported C<%options> are:

=over 4

=item current_DO

The default DO is to C<8 mg/L>.

=item DO_threshold

The default threshold is C<5 mg/L>.

If the current DO level is lower than this threshold, then your fish is lacking oxygen.

=item DO_generation_volume

This is the rate of oxygen generation.

The default value is C<0.2 mg/L per unit time>

=back

=cut

sub install {
    my $class = shift;
    my %options = @_;
    
    if ( not $options{current_DO} ) {
        $options{current_DO} = 8;
    }
    
    if ( not $options{DO_threshold} ) {
        $options{DO_threshold} = 5;
    }
    
    if ( not $options{DO_generation_volume} ) {
        $options{DO_generation_volume} = 0.2;
    }
    
    $options{is_DO_low} = 0; # might be useless :)
    
    bless \%options, "Acme::FishFarm::OxygenMaintainer";
}


=head1 DISSOLVED OXYGEN SENSOR RELATED METHODS

=head2 current_DO ( $new_DO )

Sets / returns the current DO level of the water.

C<$new_DO> is optional. If present, the current DO will be set to C<$new_DO>. Otherwise, returns the current DO reading.

=cut

sub current_DO {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( @_ ) {
        $self->{current_DO} = shift;
    } else {
        $self->{current_DO};
    }
    
}

=head2 DO_threshold

Returns the DO threshold.

=cut

sub DO_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{DO_threshold};
}

=head2 set_DO_threshold ( $new_DO_threshold )

Sets the DO threshold.

=cut

sub set_DO_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    my $new_do_threshold = shift;
    $self->{DO_threshold} = $new_do_threshold;
}

=head2 is_low_DO

Returns C<1> if the DO level is less than the threshold value. Otherwise, returns C<0>.

=cut

sub is_low_DO {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( $self->{current_DO} < $self->{DO_threshold} ) {
        return 1;
    } else {
        return 0;
    }
}


=head1 OXYGEN GENERATING RELATED METHODS

=head2 oxygen_generation_volume

Returns the oxygen generation rate.

=cut

sub oxygen_generation_volume {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{DO_generation_volume};
}

=head2 set_oxygen_generation_volume ( $new_rate )

Sets the new oxygen generation rate to C<$new_rate>.

=cut

sub set_oxygen_generation_volume {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{DO_generation_volume} = shift;
}

=head2 generate_oxygen

Pumps oxygen into the water based on the diffusion rate. The current DO value will increase every time this action is invoked.

Take note that this will generate oxygen no matter what. Make sure you check the DO content before pumping oxygen into your tank. See C<is_low_DO> for more info.

=cut

sub generate_oxygen {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{current_DO} += $self->{DO_generation_volume};
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm::OxygenMaintainer


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

1; # End of Acme::FishFarm::OxygenMaintainer

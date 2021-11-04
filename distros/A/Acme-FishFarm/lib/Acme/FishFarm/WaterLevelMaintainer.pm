package Acme::FishFarm::WaterLevelMaintainer;

use 5.006;
use strict;
use warnings;
use Carp "croak";

=head1 NAME

Acme::FishFarm::WaterLevelMaintainer - Water Level Maintainer for Acme::FishFarm

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Acme::FishFarm::WaterLevelMaintainer;

=head1 EXPORT

None

=head1 CREATION RELATED MEHODS

=head2 install ( %options )

Installs a water level maintainer system. This system only pumps water in if the water level is lower than the threshold value.

The supported C<%options> are:

=over 4

=item current_water_level

The default water level is to C<5 m>.

=item low_water_level_threshold

The default threshold is C<2 m>.

If the current water level is lower than this threshold, then you need to pump water into the tank.

=item increase_water_level_by

This is the height of the water level to increase when the water is pumped in.

The default value is C<0.5 m>.

=back

=cut

sub install {
    my $class = shift;
    my %options = @_;
    
    if ( not $options{current_water_level} ) {
        $options{current_water_level} = 5;
    }
    
    if ( not $options{low_water_level_threshold} ) {
        $options{low_water_level_threshold} = 2;
    }
    
    if ( not $options{increase_water_level_by} ) {
        $options{increase_water_level_by} = 0.5;
    }
    
    $options{is_low_water_level} = 0; # might be useless :)
    
    bless \%options, "Acme::FishFarm::WaterLevelMaintainer";
}

=head1 WATER LEVEL DETECTION RELATED METHODS

=head2 current_water_level ( $new_water_level )

Sets / returns the current water level of the water.

C<$new_water_level> is optional. If present, the current water level will be set to C<$new_water_level>. Otherwise, returns the current water level (depth) in C<metres>.

=cut

sub current_water_level {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( @_ ) {
        $self->{current_water_level} = shift;
    } else {
        $self->{current_water_level};
    }
}

=head2 low_water_level_threshold

Returns the low water level threshold.

=cut

sub low_water_level_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{low_water_level_threshold};
}

=head2 set_low_water_level_threshold ( $new_threshold )

Sets the low water level threshold.

=cut

sub set_low_water_level_threshold {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{low_water_level_threshold} = shift;
}

=head2 is_low_water_level

Returns C<1> if the DO level is less than the threshold value. Otherwise, returns C<0>.

=cut

sub is_low_water_level {
    ref( my $self = shift ) or croak "Please use this the OO way";
    if ( $self->{current_water_level} < $self->{low_water_level_threshold} ) {
        return 1;
    } else {
        return 0;
    }
}

=head1 PUMPS RELATED METHODS

For the pumping mechanism, just assume that the pumps can actually pump in certain metres of water each time :)

=head2 water_level_increase_height

Returns the height of water level to increase each time the C<pump_water_in> is called.

=cut

sub water_level_increase_height {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{increase_water_level_by};
}

=head2 set_water_level_increase_height ( $new_height )

Sets the height of water level to increase to C<$new_height>.

=cut

sub set_water_level_increase_height {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{increase_water_level_by} = shift;
}

=head2 pump_water_in

Pumps water into the tank to increase the height of the water level.

=cut

sub pump_water_in {
    ref( my $self = shift ) or croak "Please use this the OO way";
    $self->{current_water_level} += $self->{increase_water_level_by};
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::FishFarm::WaterLevelMaintainer


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


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::FishFarm::WaterLevelMaintainer

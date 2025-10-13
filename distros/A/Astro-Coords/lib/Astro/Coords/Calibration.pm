package Astro::Coords::Calibration;

=head1 NAME

Astro::Coords::Calibration - calibrations that do not have coordinates

=head1 SYNOPSIS

  $c = new Astro::Coords::Calibration();

=head1 DESCRIPTION

Occasionally observations do not have any associated coordinates.  In
particular calibration observations such as DARKs and ARRAY TESTS do
not require the telescope to be in any particular location. This class
exists in order that these types of observation can be processed in
similar ways to other observations (from a scheduling viewpoint
calibration observations always are an available target).

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.23';

use base qw/ Astro::Coords::Fixed /;


=head1 METHODS

This class inherits from C<Astro::Coords::Fixed>.

=head2 Constructor

=over 4

=item B<new>

Simply instantiates an object with an Azimuth of 0.0 degrees and an
elevation of 90 degrees. The exact values do not matter.

A label can be associated with the calibration (for example, to
include the type).

  $c = new Astro::Coords::Calibration( name => 'DARK' );

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;

  my $self = $class->SUPER::new( az => 0.0, el => 90.0, units => 'deg' );
  $self->name( $args{name} ) if exists $args{name};

  return $self;
}

=back

=head2 General Methods

=over 4

=item B<type>

Return the coordinate type. In this case always return "CAL".

=cut

sub type {
  return "CAL";
}

=item B<array>

Returns a summary of the object in an 11 element array. All elements
are undefined except the first. This contains "CAL".

=cut

sub array {
  my $self = shift;
  return ($self->type,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef);
}

=item B<status>

Return a status string describing the current coordinates. For calibration
objects this is very simple.

=cut

sub status {
  my $self = shift;
  my $string;

  $string .= "Coordinate type:CAL\n";
  if (defined $self->telescope) {
    $string .= "Telescope:      " . $self->telescope->fullname . "\n";
    if ($self->isObservable) {
      $string .= "The target is currently observable\n";
    } else {
      $string .= "The target is not currently observable\n";
    }
  }

  return $string;

}

=item B<isObservable>

Determines whether the observation is observable. Since a calibration
observation (defined as an observation that does not move the telescope)
is always observable this methods always returns true.

=cut

sub isObservable {
  return 1;
}

=item B<stringify>

Returns stringified summary of the object. Always returns the
C<type()>.

=cut

sub stringify {
  my $self = shift;
  return $self->type;
}

=item B<summary>

Return a one line summary of the coordinates.
In the future will accept arguments to control output.

  $summary = $c->summary();

=cut

sub summary {
  my $self = shift;
  my $name = $self->name;
  $name = '' unless defined $name;
  return sprintf("%-16s  %-12s  %-13s    CAL",$name,'','');
}

=item B<apply_offset>

Overrided method to prevent C<Astro::Coords::apply_offset> being
called on this subclass.

=cut

sub apply_offset {
  croak 'apply_offset: attempting to apply an offset to a calibration';
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::PAL> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;

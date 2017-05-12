package Astro::Flux;

=head1 NAME

Astro::Flux - Class for handling astronomical flux quantities.

=head1 SYNOPSIS

  use Astro::Flux;

  $flux = new Astro::Flux( $quantity, $units, $waveband );

  $quantity = $flux->quantity('mag');

=head1 DESCRIPTION

Class for handling astronomical flux quantities. This class does
not currently support conversions from one flux type to another
(say, from magnitudes to Janskies) but may in the future.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Number::Uncertainty;

our $VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::Flux> object.

  $flux = new Astro::Flux( $quantity, $type, $waveband );

The first three parameters must be defined. They are:

  quantity - numerical value for the flux, my be a primitive, or a
             C<Number::Uncertainty> object.
  type - type of flux. Can be any string.
  waveband - waveband for the given flux. Must be an C<Astro::WaveBand> object.

If any of the parameters are undefined, the constructor will throw
an error. If the waveband parameter is not an C<Astro::WaveBand> object,
the constructor will throw an error.

The type is case-insensitive for lookups using the C<quantity> method.

A fourth optional argument may be passed; this is a hash containing
the following optional keys:

  quality - an C<Misc::Quality> object denoting quality flags for the
    C<Astro::Flux> object.
  reference_waveband - an C<Astro::WaveBand> object denoting a reference
    waveband for the C<Astro::Flux> object. This is used for determining
    magnitudes when deriving them from C<Astro::FluxColor> objects. See
    C<Astro::Fluxes>.
  datetime - an C<DateTime> object which is the datetime of observation for the
    measurement in the C<Astro::Flux> object.
  obsid - An array reference to a list of observation identifiers. Can be
    used to identify the observation(s) from which this measurement was
    taken (e.g. from a filename).

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $quantity = shift;
  my $type = shift;
  my $waveband = shift;

  my %args = @_;

  croak "Quantity must be defined"
    unless defined $quantity;

  unless ( UNIVERSAL::isa($quantity, "Number::Uncertainty" ) ) {
     $quantity = new Number::Uncertainty( Value => $quantity );
  }

  croak "Type must be defined"
    unless defined $type;

  croak "Waveband must be defined"
    unless defined $waveband;

  unless ( UNIVERSAL::isa($waveband, "Astro::WaveBand") ) {
     $waveband = new Astro::WaveBand( Filter => $waveband );
  }

  my $flux = {};

  $flux->{QUANTITY} = { uc($type) => $quantity };
  $flux->{WAVEBAND} = $waveband;
  $flux->{TYPE} = uc( $type );

  if( defined( $args{'quality'} ) &&
      UNIVERSAL::isa( $args{'quality'}, "Misc::Quality" ) ) {
    $flux->{QUALITY} = $args{'quality'};
  }
  if( defined( $args{'reference_waveband'} ) &&
      UNIVERSAL::isa( $args{'reference_waveband'}, "Astro::WaveBand" ) ) {
    $flux->{REFERENCE_WAVEBAND} = $args{'reference_waveband'};
  }

  if( defined( $args{'datetime'} ) &&
      UNIVERSAL::isa( $args{'datetime'}, "DateTime" ) ) {
    $flux->{TIME} = $args{'datetime'};
  }

  if( defined( $args{'obsid'} ) ) {
    $flux->{OBSID} = $args{'obsid'};
  }

  bless( $flux, $class );
  return $flux;

}

=back

=head2 Accessor Methods

=over 4

=item B<quantity>

Returns the quantity for a requested flux type.

  my $mag = $flux->quantity('mag');

No conversions are done between types. What you put in via the
constructor is all you can get out, so if you specify the type
to be 'magnitude' and you ask for a 'mag', this method will
throw an error.

The type is case-insensitive.

=cut

sub quantity {
  my $self = shift;
  my $type = uc(shift);

  return undef if ! defined $type;

  croak "Cannot translate between flux types"
    if ! defined( $self->{QUANTITY}->{$type} );

  my $number = $self->{QUANTITY}->{$type};
  my $value = $number->value();
  return $value;
}


=item B<error>

Returns the error in the quantity for a requested flux type.

  my $mag = $flux->error('mag');

No conversions are done between types. What you put in via the
constructor is all you can get out, so if you specify the type
to be 'magnitude' and you ask for a 'mag', this method will
throw an error.

The type is case-insensitive.

Errors are only returned if one was created with the object.

=cut

sub error {
  my $self = shift;
  my $type = uc(shift);

  return undef if ! defined $type;

  croak "Cannot translate between flux types"
    if ! defined( $self->{QUANTITY}->{$type} );

  my $number = $self->{QUANTITY}->{$type};
  my $error = $number->error();
  return $error;
}


=item B<waveband>

Returns the waveband for the given flux object.

  my $waveband = $flux->waveband;

Returns an C<Astro::WaveBand> object.

=cut

sub waveband {
  my $self = shift;

  return $self->{WAVEBAND};
}

=item B<quality>

Returns the quality for the given flux object.

  my $quality = $flux->quality;

Returns an C<Misc::Quality> object if defined. If not, returns undef.

=cut

sub quality {
  my $self = shift;

  return $self->{QUALITY};
}

=item B<reference_waveband>

Returns the reference waveband for the given flux object.

  my $ref_waveband = $flux->reference_waveband;

Returns an C<Astro::WaveBand> object if defined. If not, returns undef.

=cut

sub reference_waveband {
  my $self = shift;

  return $self->{REFERENCE_WAVEBAND};
}


=item B<datetime>

Sets or returns the datetime stamp for the given flux object.

  my $datetime = $flux->datetime;
  $flux->datetime( new DateTime );

Returns an C<Date::datetime> object if defined. If not, returns undef.

=cut

sub datetime {
  my $self = shift;
 
  if (@_) {
    $self->{TIME} = shift;
  }

  return $self->{TIME};
}

=item B<obsid>

Sets or returns the observation ID for the given flux object.

  my $obsid = $flux->obsid;
  $flux->obsid( $obsid );

Returns an array reference if defined. If not, returns undef.

=cut

sub obsid {
  my $self = shift;

  if( @_ ) {
    $self->{OBSID} = shift;
  }
  return $self->{OBSID};
}

=item B<type>

Returns the type of flux measurement stored.

  my $type = $flux->type;

Cannot be used to set the type.

=cut

sub type {
  my $self = shift;
  return $self->{TYPE};
}

=back

=head1 REVISION

 $Id: Flux.pm,v 1.14 2005/06/24 21:02:11 bradc Exp $

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 - 2005 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

package Astro::SIMBAD::Result::Object;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::SIMBAD::Result:Object

#  Purposes:
#    Perl wrapper for the SIMBAD database

#  Language:
#    Perl module

#  Description:
#    This module wraps the SIMBAD online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Object.pm,v 1.3 2005/06/08 01:38:17 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::SIMBAD::Result::Object - A individual astronomical object 

=head1 SYNOPSIS

  $object = new Astro::SIMBAD::Result::Object( Name   => $object_name,
                                               Type   => $object_type,
                                               Long   => $long_type,
                                               Frame => \@coord_frame,
                                               RA     => $ra,
                                               Dec    => $declination,
                                               Spec   => $spectral_type,
                                               URL    => $url );

=head1 DESCRIPTION

Stores meta-data about an individual astronomical object in the
Astro::SIMBAD::Result object returned by an Astro::SIMBAD::Query object.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Object.pm,v 1.3 2005/06/08 01:38:17 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $paper = new Astro::SIMBAD::Result::Object(  );

returns a reference to an SIMBAD astronomical object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { NAME    => undef,
		      TARGET  => undef,
                      TYPE    => undef,
                      LONG    => undef,
                      FRAME   => [],
                      RA      => undef,
                      DEC     => undef,
                      SPEC    => undef,
                      URL     => undef,
		      BMAG    => undef,
		      VMAG    => undef,
		      IDENT   => [],
		      PM      => [],
		      PLX     => undef,
		      RADIAL  => undef,
		      REDSHIFT=> undef,
		  }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<name>

Return (or set) the name of the object

   $name = $object->name();
   $object->name( $name );

Query types:  list, object

=cut

sub name {
  my $self = shift;
  if (@_) {
    $self->{NAME} = shift;
  }
  return $self->{NAME};
}

=item B<target>

Return (or set) the target name of the object. Available whenever a target is
specified in the query. The returned value is identical to the query parameter,
except that it is normalized (spaces replaced with '+' characters).
This is useful because name() may return a different designation than the
target that is supplied as a query parameter.

   $target = $object->target();
   $object->target( $target );

Query types:  list, object

=cut

sub target {
  my $self = shift;
  if (@_) {
    $self->{TARGET} = shift;
  }
  return $self->{TARGET};
}

=item B<type>

Return (or set) the (short) type of the object

   $type = $object->type();
   $object->type( $type );

Query types:  list

=cut

sub type {
  my $self = shift;
  if (@_) {
    $self->{TYPE} = shift;
  }
  return $self->{TYPE};
}

=item B<long>

Return (or set) the (long) type of the object

   $long_type = $object->long();
   $object->long( $long_type );

Query types:  list, object

=cut

sub long {
  my $self = shift;
  if (@_) {
    $self->{LONG} = shift;
  }
  return $self->{LONG};
}

=item B<frame>

Return (or set) the system the R.A. and DEC stored in the object are
defined in, e.g. Co-ordinate Frame FK5, Epoch 1950 and Equinox 2000

   @system = $object->frame();
   $object->frame( \@system );

where @system would be [ "FK5", 1950.0, 2000.0 ]. If called in a scalar
context will return a string of the form "FK5 1950/2000" to

Query types:  list, object

=cut

sub frame {
  my $self = shift;

  if (@_) {
    # take a local copy to avoid "copy of copy" problems
    my $frame = shift;
    @{$self->{FRAME}} = @{$frame};
  }
   
  my $stringify = 
     "${$self->{FRAME}}[0] ${$self->{FRAME}}[1]/${$self->{FRAME}}[2]";
     
  return wantarray ? @{$self->{FRAME}} : $stringify;
}

=item B<ra>

Return (or set) the R.A. of the object

   $ra = $object->ra();
   $object->ra( $ra );

Query types:  list, object

=cut

sub ra {
  my $self = shift;
  if (@_) {
    $self->{RA} = shift;
  }
  return $self->{RA};
}

=item B<dec>

Return (or set) the Declination of the object

   $dec = $object->dec();
   $object->dec( $dec );

Query types:  list, object

=cut

sub dec {
  my $self = shift;
  if (@_) {
    $self->{DEC} = shift;
  }
  return $self->{DEC};
}

=item B<spec>

Return (or set) the Spectral Type of the object

   $spec_type = $object->spec();
   $object->spec( $spec_type );

Query types:  list, object

=cut

sub spec {
  my $self = shift;
  if (@_) {
    $self->{SPEC} = shift;
  }
  return $self->{SPEC};
}

=item B<url>

Return (or set) the followup URL for the object where more information
can be found via SIMBAD, including pointers to reduced data.

   $url = $object->url();
   $object->url( $url );

=cut

sub url {
  my $self = shift;
  if (@_) {
    $self->{URL} = shift;
  }
  return $self->{URL};
}

=item B<bmag>

Return (or set) the B-magnitude of the object

   $bmag = $object->bmag();
   $object->bmag( $bmag );

Query types:  list, object

=cut

sub bmag {
  my $self = shift;
  if (@_) {
    $self->{BMAG} = shift;
  }
  return $self->{BMAG};
}

=item B<vmag>

Return (or set) the V-magnitude of the object

   $vmag = $object->vmag();
   $object->vmag( $vmag );

Query types:  list, object

=cut

sub vmag {
  my $self = shift;
  if (@_) {
    $self->{VMAG} = shift;
  }
  return $self->{VMAG};
}

=item B<ident>

Return (or append) the array of object identifiers

   @ident = $object->ident();
   $object->ident( @ident );

Query types:  object

=cut

sub ident {
  my $self = shift;
  if (@_) {
    my $idarray = shift;
    @{$self->{IDENT}} = @{$idarray};
  }
  return $self->{IDENT};
}

=item B<pm>

Return (or set) the proper motion of the object in mas/year

   @pm = $object->pm();
   $object->pm( @pm );

Query types:  object

=cut

sub pm {
  my $self = shift;
  if (@_) {
    push @{$self->{PM}}, @_[0..1];
  }
  return $self->{PM};
}

=item B<plx>

Return (or set) the parallax of the object

   $plx = $object->plx();
   $object->plx( $plx );

Query types:  object

=cut

sub plx {
  my $self = shift;
  if (@_) {
    $self->{PLX} = shift;
  }
  return $self->{PLX};
}

=item B<radial>

Return (or set) the radial velocity (km/s) of the object

   $radial = $object->radial();
   $object->radial( $radial );

Query types:  object

=cut

sub radial {
  my $self = shift;
  if (@_) {
    $self->{RADIAL} = shift;
  }
  return $self->{RADIAL};
}

=item B<redshift>

Return (or set) the redshift of the object

   $redshift = $object->redshift();
   $object->redshift( $redshift );

Query types:  object

=cut

sub redshift {
  my $self = shift;
  if (@_) {
    $self->{REDSHIFT} = shift;
  }
  return $self->{REDSHIFT};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

  $object->configure( %options );

Takes a hash as argument with the following keywords:

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys storing the values
  # in the object if they exist
  for my $key (qw / Name Type Long Frame RA Dec Spec URL /) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}


# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.


=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  

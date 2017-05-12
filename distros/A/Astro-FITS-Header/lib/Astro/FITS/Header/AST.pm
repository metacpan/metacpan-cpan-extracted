package Astro::FITS::Header::AST;

=head1 NAME

Astro::FITS::Header::AST - Manipulates FITS headers from an AST object

=head1 SYNOPSIS

  use Astro::FITS::Header::AST;

  $header = new Astro::FITS::Header::AST( FrameSet => $wcsinfo );
  $header = new Astro::FITS::Header::AST( FrameSet => $wcsinfo,
                                          Encoding => 'FITS-IRAF' );

  $header = new Astro::FITS::Header::AST( Cards => \@cards );

=head1 DESCRIPTION

This module makes use of the L<Starlink::AST|Starlink::AST> module to read
the FITS HDU from an AST FrameSet object.

It stores information about a FITS header block in an object. Takes an hash
as an argument, with an array reference pointing to an Starlink::AST
FramSet object.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;
use base qw/ Astro::FITS::Header /;
use Carp;

require Starlink::AST;

$VERSION = 3.01;

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<configure>

Reads a FITS header from a Starlink::AST FrameSet object

  $header->configure( FrameSet => $wcsinfo );

Base class initialisation also works:

  $header->configure( Cards => \@cards );

Accepts a reference to an Starlink::AST FrameSet object.

If a specific encoding is required, this can be specified using
the Encoding argument. Default is FITS-WCS if no Encoding is given.
Note that not all framesets can be encoded using FITS-WCS.

  $header->configure( FrameSet => $wcsinfo, Encoding => "Native" );

If Encoding is specified but undefined, the default will be decided
by AST.

=cut

sub configure {
  my $self = shift;
  my %args = @_;

  # initialise the inherited status to OK.
  my $status = 0;

  return $self->SUPER::configure(%args)
    if exists $args{Cards} or exists $args{Items};

  # read the args hash
  unless (exists $args{FrameSet}) {
     croak("Arguement hash does not contain FrameSet or Cards");
  }

  my $wcsinfo = $args{FrameSet};
  my @cards;
  {
     my $fchan = new Starlink::AST::FitsChan(
                                      sink => sub { push @cards, $_[0] } );
     if (exists $args{Encoding}) {
       if (defined $args{Encoding}) {
         # use AST default if undef is supplied
         $fchan->Set( Encoding => $args{Encoding} );
       }
     } else {
       # Historical default
       $fchan->Set( Encoding => "FITS-WCS" );
     }
     $status = $fchan->Write( $wcsinfo );
  }
  return $self->SUPER::configure( Cards => \@cards );
}

# shouldn't need to do this, croak! croak!
sub writehdr {
  my $self = shift;
  croak("Not yet implemented");
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 SEE ALSO

C<Starlink::AST>, C<Astro::FITS::Header>

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2011 Science and Technology Facilities Council.
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

# L A S T  O R D E R S ------------------------------------------------------

1;

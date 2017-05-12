package Astro::FITS::Header::GSD;

=head1 NAME

Astro::FITS::Header::GSD - Manipulate FITS headers from GSD files

=head1 SYNOPSIS

  use Astro::FITS::Header::GSD;

  $hdr = new Astro::FITS::Header::GSD( Cards => \@cards );
  $hdr = new Astro::FITS::Header::GSD( gsdobj => $gsd );
  $hdr = new Astro::FITS::Header::GSD( File => $file );

=head1 DESCRIPTION

This module makes use of the Starlink L<GSD|GSD> module to read from
a GSD header.

It stores information about a FITS header block in an object. Takes an
hash as an argument, with either an array reference pointing to an
array of FITS header cards, or a filename, or (alternatively) a GSD
object.

=cut

use strict;
use Carp;
use GSD;

use Astro::FITS::Header::Item;
use base qw/ Astro::FITS::Header /;

use vars qw/ $VERSION /;

$VERSION = 3.01;

=head1 METHODS

=over 4

=item B<configure>

Reads a header from a GSD file.

  $hdr->configure( Cards => \@cards );
  $hdr->configure( Items => \@items );
  $hdr->configure( gsdobj => $gsd );
  $hdr->configure( File => $filename );

Accepts a GSD object or a filename. If both C<gsdobj> and C<File> keys
exist, C<gsdobj> key takes priority.

=cut

sub configure {
  my $self = shift;

  my %args = @_;

  my ($indf, $started);
  my $task = ref($self);

  return $self->SUPER::configure(%args) if exists $args{Cards} or
    exists $args{Items};

  my $gsd;
  if (exists $args{gsdobj} && defined $args{gsdobj}) {
    $gsd = $args{gsdobj};

    croak "gsd object must be of class 'GSD'"
      unless UNIVERSAL::isa($gsd, 'GSD');

  } elsif (exists $args{File}) {
    # Open the file
    $gsd = new GSD( $args{File} );

    croak "Error opening gsd file $args{File}"
      unless defined $gsd;

  } else {
    croak "Argument hash does not contain gsdobj, File or Cards!";
  }

  # Somewhere to store the FITS information
  my @cards;


  # Read through all the items extracting the scalar items
  for my $i (1..$gsd->nitems) {

    my ($name, $units, $type, $array) = $gsd->Item( $i );

    if (!$array) {
      # Only scalars
      my $value = $gsd->GetByNum( $i );

      # Generate a comment string
      my $comment = '';
      $comment .= "[$units]" if $units;

      if (length($name) > 8 ) {
	$comment .= " Name shortened from $name";
	$name = substr($name, 0, 8);
      }

      # We need to convert the type from GSD to one that's a FITS
      # type.
      if( ( $type eq 'R' ) || ( $type eq 'D' ) ) {
        $type = "FLOAT";
      } elsif( ( $type eq 'I' ) || ( $type eq 'W' ) || ( $type eq 'B' ) ) {
        $type = "INT";
      } elsif( $type eq 'C' ) {
        $type = "STRING";
      } elsif( $type eq 'L' ) {
        $type = "LOGICAL";
      }

      # We do not have an actual FITS style string so we just
      # create the item directly
      push(@cards, new Astro::FITS::Header::Item(
						 Keyword => $name,
						 Comment => $comment,
						 Value => $value,
             Type => $type,
						));
    }

  }

  # Configure the object
  $self->SUPER::configure( Items => \@cards );

  return;

}

=item B<writehdr>

The GSD library is read-only. The writehdr method is not implemented
for this sub-class.

=cut

sub writehdr {
  croak "The GSD library is read-only. The writehdr method is not implemented
for this sub-class.";
}

=back

=head1 NOTES

This module requires the Starlink L<GSD|GSD> module.

GSD supports keys that are longer than the 8 characters allowed as
part of the FITS standard. GSD keys are truncated to 8 characters
by this module.

=head1 SEE ALSO

L<NDF>, L<Astro::FITS::Header>, L<Astro::FITS::Header::Item>
L<Astro::FITS::Header::CFITSIO>, L<Astro::FITS::Header::NDF>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008-2011 Science & Technology Facilities Council.
Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
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

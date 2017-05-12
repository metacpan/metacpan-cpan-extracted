package Astro::FITS::Header::CFITSIO;

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::Header::CFITSIO - Manipulates FITS headers from a FITS file

=head1 SYNOPSIS

  use Astro::FITS::Header::CFITSIO;

  $header = new Astro::FITS::Header::CFITSIO( Cards => \@array );
  $header = new Astro::FITS::Header::CFITSIO( File => $file );
  $header = new Astro::FITS::Header::CFITSIO( fitsID => $ifits );

  $header->writehdr( File => $file );
  $header->writehdr( fitsID => $ifits );

=head1 DESCRIPTION

This module makes use of the L<CFITSIO|CFITSIO> module to read and write
directly to a FITS HDU.

It stores information about a FITS header block in an object. Takes an
hash as an argument, with either an array reference pointing to an
array of FITS header cards, or a filename, or (alternatively) and FITS
identifier.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::FITS::Header::Item;
use base qw/ Astro::FITS::Header /;

use Astro::FITS::CFITSIO qw / :longnames :constants /;
use Carp;

$VERSION = 3.02;

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id$

=head1 METHODS

=over 4

=item B<configure>

Reads a FITS header from a FITS HDU

  $header->configure( Cards => \@cards );
  $header->configure( fitsID => $ifits );
  $header->configure( File => $file );
  $header->configure( File => $file, ReadOnly => $bool );

Accepts an FITS identifier or a filename. If both fitsID and File keys
exist, fitsID key takes priority.

If C<File> is specified, the file is normally opened in ReadWrite
mode.  The C<ReadOnly> argument takes a boolean value which determines
whether the file is opened ReadOnly.

=cut

sub configure {
  my $self = shift;

  my %args = ( ReadOnly => 0, @_ );

  # itialise the inherited status to OK.
  my $status = 0;
  my $ifits;

  return $self->SUPER::configure(%args)
    if exists $args{Cards} or exists $args{Items};

  # read the args hash
  if (exists $args{fitsID}) {
     $ifits = $args{fitsID};
  } elsif (exists $args{File}) {
     $ifits = Astro::FITS::CFITSIO::open_file( $args{File},
		  $args{ReadOnly} ? Astro::FITS::CFITSIO::READONLY() :
			            Astro::FITS::CFITSIO::READWRITE(),
					       $status );
  } else {
     croak("Arguement hash does not contain fitsID, File or Cards");
  }

  # file sucessfully opened?
  if( $status == 0 ) {

     # Get size of FITS header
     my ($numkeys, $morekeys);
     $ifits->get_hdrspace( $numkeys, $morekeys, $status);

     # Set the FITS array to empty
     my @fits = ();

     # read the cards. Note that CFITSIO doesn't include the END card
     # in it's counting
     for my $i (1 .. $numkeys) {
        $ifits->read_record($i, my $card, $status);
        push(@fits, $card);
     }

     # add an END card. previously this was extracted from CFITSIO
     # by reading an extra card.  however, the header may not have
     # been completed by CFITSIO, so that extra card might not exist.
     push @fits, Astro::FITS::Header::Item->new( Keyword => 'END')->card;

     if ($status == 0) {
        # Parse the FITS array
        $self->SUPER::configure( Cards => \@fits );
     } else {
        # Report bad exit status
        croak("Error $status reading FITS array");
     }

     # Look at the name of the file as it was passed in. If there is a FITS
     # extension specified, then this is a single fits image that you want
     # read.  If there isn't one specified, then we should read each of the
     # extensions that exist in the file, if in fact there are any.

     if ( exists $args{File} )
     {
       my $ext;
       fits_parse_extnum($args{File},$ext,$status);
       my @subfrms = ();
       if ($ext == -99) {
         my $nhdus;
         $ifits->get_num_hdus($nhdus,$status);
         foreach my $ihdu (1 .. $nhdus-1) {
	   my $subfr = sprintf("%s[%d]",$args{File},$ihdu);
	   my $sself = $self->new(File=>$subfr, ReadOnly => $args{ReadOnly});
	   push @subfrms,$sself;
         }
       }
       $self->subhdrs(@subfrms);
     }
  }

  # clean up
  if ( $status != 0 ) {
     croak("Error $status opening FITS file");
  }

  # close file, but only if we opened it
  $ifits->close_file( $status )
    unless exists $args{fitsID};

  return;

}

# W R I T E H D R -----------------------------------------------------------

=item B<writehdr>

Write a FITS header to a FITS file

  $header->writehdr( File => $file );
  $header->writehdr( fitsID => $ifits );

Its accepts a FITS identifier or a filename. If both fitsID and File keys
exist, fitsID key takes priority.

Returns undef on error, true if the header was written successfully.

=cut

sub writehdr {
  my $self = shift;
  my %args = @_;

  return $self->SUPER::configure(%args) if exists $args{Cards};

  # itialise the inherited status to OK.
  my $status = 0;
  my $ifits;

  # read the args hash
  if (exists $args{fitsID}) {
     $ifits = $args{fitsID};
  } elsif (exists $args{File}) {
     $ifits = Astro::FITS::CFITSIO::open_file( $args{File},
			 Astro::FITS::CFITSIO::READWRITE(), $status );
  } else {
     croak("Argument hash does not contain fitsID, File or Cards");
  }

  # file sucessfully opened?
  if( $status == 0 ) {

    # Get size of FITS header
    my ($numkeys, $morekeys);
    $ifits->get_hdrspace( $numkeys, $morekeys, $status);

    # delete the cards in the current header. as cards are deleted the
    # ones below it are shifted up (according to the CFITSIO docs).
    # we thus delete from the bottom up to avoid all of that work.
    $ifits->delete_record( $numkeys--, $status )
      while $numkeys;

    # write the new cards, not including END card if it exists
    my @cards = $self->cards;
    if ( defined (my $end_card = $self->index('END')) )
      { splice( @cards, $end_card, 1 ) }
    $ifits->write_record($_, $status ) foreach @cards;

  }

  # clean up
  if ( $status != 0 ) {
     croak("Error $status opening FITS file");
  }

  # close file, but only if we opened it
  $ifits->close_file( $status )
    unless exists $args{fitsID};

  return;

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 NOTES

This module requires Pete Ratzlaff's L<Astro::FITS::CFITSIO> module,
and  William Pence's C<cfitsio> subroutine library (v2.1 or greater).

=head1 SEE ALSO

L<Astro::FITS::Header>, L<Astro::FITS::Header::Item>, L<Astro::FITS::Header::NDF>, L<Astro::FITS::CFITSIO>

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Jim Lewis E<lt>jrl@ast.cam.ac.ukE<gt>,
Diab Jerius.

=head1 COPYRIGHT

Copyright (C) 2007-2009 Science & Technology Facilities Council.
Copyright (C) 2001-2006 Particle Physics and Astronomy Research Council.
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

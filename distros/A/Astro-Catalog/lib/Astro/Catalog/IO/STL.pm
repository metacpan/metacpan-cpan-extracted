package Astro::Catalog::IO::STL;

=head1 NAME

Astro::Catalog::IO::STL - STL catalogue I/O for Astro::Catalog

=head1 SYNOPSIS

$cat = Astro::Catalog::IO::STL->_read_catalog( \@lines );

=head1 DESCRIPTION

This class provides read and write methods for catalogues in the CURSA
small text list (STL) catalogue format. The methods are not public and
should, in general, only be called from the C<Astro::Catalog>
C<write_catalog> method.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Carp;

use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/$VERSION $DEBUG/;

$VERSION = '4.34';
$DEBUG = 0;

=begin __PRIVATE_METHODS__

=head1 Private Methods

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog>
object containing the catalogue entries.

  $cat = Astro::Catalog::IO::STL->_read_catalog( \@lines );

The catalogue lines must include column definitions (lines starting
with a C) so that the parser knows in which column values lie.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  if( ref( $lines) ne 'ARRAY' ) {
    croak "Must supply catalogue contents as a reference to an array";
  }

  my @lines = @$lines; # Dereference, make own copy.

  # Concatenate all continuation lines (they start with a colon).
  chomp @lines;
  my $all_lines = join( "\n", @lines );
  $all_lines =~ s/\n://g;
  @lines = split( "\n", $all_lines );

  # Create an Astro::Catalog object.
  my $catalog = new Astro::Catalog();

  # Set a counter for star ID.
  my $id = 0;

  # Set up columns.
  my $ra_column = -1;
  my $dec_column = -1;
  my $id_column = -1;

  # Do we convert from DMS to radians?
  my $ra_convert = 0;
  my $dec_convert = 0;

  # Are we in the main table yet?
  my $intable = 0;

  # Loop through the lines.
  for( @lines ) {

    my $line = $_;

    # If we're on a column line that starts with a C, check to see
    # if it's describing where the position identifier, RA, or Dec.
    if( $line =~ /^C/ ) {
      my @column = split( /\s+/, $line );
      if( $column[1] =~ /pident/i ) {
        $id_column = $column[3] - 1;
      } elsif( $column[1] =~ /ra/i ) {
        $ra_column = $column[3] - 1;
        if( $line =~ /TBLFMT=HOURS/ ) {
          # Convert DMS to radians.
          $ra_convert = 1;
        }
      } elsif( $column[1] =~ /dec/i ) {
        $dec_column = $column[3] - 1;
        if( $line =~ /TBLFMT=DEGREES/ ) {
          # Convert DMS to radians.
          $dec_convert = 1;
        }
      } elsif( ( $column[1] =~ /^[a-z]$/i ) ||
               ( $column[1] =~ /^[a-z]_[a-z]$/i ) ) {
        warnings::warnif("Magnitude description found, magnitudes not yet supported");
      }
      next;
    }

    my $equinox = 0;

    # If it's a line starting with a P, then this is a parameter
    # for the coordinate system.
    if( $line =~ /^P/ ) {
      my @column = split( /\s+/, $line );
      if( $column[1] eq 'EQUINOX' ) {
        ( $equinox = $column[3] ) =~ s/\'//g;
      }
      next;
    }

    # We need to wait until the BEGINTABLE line.
    next if( ! $intable && $line !~ /^BEGINTABLE/ );

    if( $line =~ /^BEGINTABLE/ ) {
      $intable = 1;
      next;
    }

    # If we've made it here we're in the table.

    # Have a winge if we don't have RA/Dec.
    if( ( $ra_column == -1 ) ||
        ( $dec_column == -1 ) ) {
      croak "STL file does not contain RA and Dec information";
    }

    $line =~ s/^\s+//;

    next if length( $line ) == 0;

    my @fields = split( /\s+/, $line );

    # Set the star's ID.
    my $name;
    if( $id_column != -1 ) {
      $name = $fields[$id_column];
    } else {
      $name = $id;
    }

    # Create a temporary Astro::Catalog::Star object.
    my $star = new Astro::Catalog::Star();

    # Do RA/Dec conversions to radians, if necessary.
    my $ra = Astro::Coords::Angle::Hour->new( $fields[$ra_column],
                                              units => ($ra_convert ? "sex" : "rad")
                                            );
    my $dec = Astro::Coords::Angle->new( $fields[$dec_column],
                                         units => ($dec_convert ? "sex" : "rad" )
                                         );

    # Create an Astro::Coords object, assuming J2000 for RA/Dec.
    my $coords = new Astro::Coords( type => ( $equinox ? $equinox : 'J2000' ),
                                    ra => $ra,
                                    dec => $dec,
                                    name => $name,
                                    units => 'radians',
                                  );

    # And push it into the Astro::Catalog::Star object.
    $star->coords( $coords );

    # Set default "good" quality.
    $star->quality( 0 );

    # And push the star onto the catalog.
    $catalog->pushstar( $star );

    $id++;

  }

  $catalog->origin( 'IO::STL' );
  return $catalog;

}

=item B<_write_catalog>

Create an output catalogue in the STL format and return the lines
in an array.

  $ref = Astro::Catalog::IO::STL->_write_catalog( $catalog );

Argument is an C<Astro::Catalog> object.

=cut

sub _write_catalog {
  my $class = shift;
  my $catalog = shift;

  # An array to hold the output.
  my @return;

  # First, the preamble.
  push( @return, "!+" );
  push( @return, "!  This catalogue is formatted as a CURSA small text list (STL)." );
  push( @return, "!  For a description of this format see Starlink User Note 190." );
  push( @return, "!-" );
  push( @return, "" );

  # Now the header describing the output columns.
  push( @return, "C  PIDENT   INTEGER   1     EXFMT=I6" );
  push( @return, ":    COMMENTS='Position identifier'" );
  push( @return, "C  RA       DOUBLE    2     EXFMT=D19.10" );
  push( @return, ":    UNITS='RADIANS{hms.1}'" );
  push( @return, ":    COMMENTS='Right ascension'" );
  push( @return, "C  Dec      DOUBLE    3     EXFMT=D19.10" );
  push( @return, ":    UNITS='RADIANS{dms}'" );
  push( @return, ":    COMMENTS='Declination'" );
  push( @return, "" );

  # Begin the table.
  push( @return, "BEGINTABLE" );

  # And now the actual data. Loop through the stars in the catalogue.
  my $stars = $catalog->stars();

  foreach my $star ( @$stars ) {
    my $output_string;

    my $id_string = sprintf( "%6d", $star->id );
    my $ra_string = sprintf( "%19.10e", $star->coords->ra->radians );
    $ra_string =~ s/e/E/;
    my $dec_string = sprintf( "%19.10e", $star->coords->dec->radians );
    $dec_string =~ s/e/E/;

    $output_string = $id_string . $ra_string . $dec_string;
    push( @return, $output_string );
  }

  # And return.
  return \@return;
}

=back

=head1 FORMAT

The STL format is specified in SUN/190
[http://www.starlink.rl.ac.uk/star/docs/sun190.htx//sun190.html] and SSN/75
[http://www.starlink.rl.ac.uk/star/docs/ssn75.htx//ssn75.html], both by
Clive Davenhall.

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>.

=head1 COPYRIGHT

Copyright (C) 2004-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;

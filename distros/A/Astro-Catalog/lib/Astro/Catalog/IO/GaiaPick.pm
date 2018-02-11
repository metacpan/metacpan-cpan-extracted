package Astro::Catalog::IO::GaiaPick;

=head1 NAME

Astro::Catalog::IO::GaiaPick - Catalogue reader for GAIA Pick Object files

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::GaiaPick->_read_catalog( \@lines );

=head1 DESCRIPTION

This class provides a read method for catalogues in the GAIA Pick
Object catalogue format. This format is written by the Starlink GAIA
application when a user requests the result of a "Pick Object" are to
be saved. The method is not public and should, in general, only be
called from the C<Astro::Catalog> C<read_catalog> method.

=cut


use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION $DEBUG /;
use Carp;
use Data::Dumper;

use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords;

use base qw/ Astro::Catalog::IO::ASCII /;

$DEBUG = 0;
$VERSION = '4.33';

# Named Constants for column positions
use constant NAME => 0;
use constant XPIX => 1;
use constant YPIX => 2;
use constant RA   => 3;
use constant DEC  => 4;
use constant EQUINOX => 5;
use constant ANGLE => 6;
use constant PEAK => 7;
use constant BACKGROUND => 8;
use constant FWHM_X => 9;
use constant FWHM_Y => 11;

=begin __PRIVATE_METHODS__

=head1 Private Methods

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Read contents of a GaiaPick log file.

  $cat = Astro::Catalog::IO::TST->_read_catalog( \@lines );

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  # Local copy of array [may be a problem for very large catalogues]
  my @lines = @$lines;

  # Remove the first line from the array
  # without trying to parse the column names
  # We have defined indices at the top.
  shift(@lines);

  # Somewhere to put the stars
  my @stars;

  # Star ID [integer]
  my $currid = 0;

  # Loop through the array until we run out of lines
  # Expect lines to be read in pairs
  while (scalar(@lines) >= 2) {
    my $tstamp   = shift(@lines);
    my $pickline = shift(@lines);

    # Skip if we have a blank line [should be rare]
    next unless defined $tstamp;
    next unless defined $pickline;
    next unless $pickline =~ /\d/;
    next unless $tstamp =~ /\d/;

    # Parse the time stamp. Need to work out where to put the
    # time since this is not an observation date (epoch).
    # Think of a concept for Astro::Catalog::Star
    # catalogDate ??

    # Parse the actual star information. Split on space.
    my @chunks = split(/\s+/,$pickline);

    # The first column refers to the file name so is
    # effectively the field ID.

    # We need to create our own unique star ID for now.
    # Use an integer starting at 1.
    $currid ++;

    # Coordinate object
    my $c = new Astro::Coords( name => $currid,
                               ra => $chunks[RA],
                               dec => $chunks[DEC],
                               type => $chunks[EQUINOX],
                               units => 'sex',
                             );

    my $star = new Astro::Catalog::Star( ID => $currid,
                                         Field => $chunks[0],
                                         Coords => $c,
                                         X => $chunks[XPIX],
                                         Y => $chunks[YPIX],
                                       );

    push(@stars, $star);
  }

  my $cat = new Astro::Catalog( Stars => \@stars,
                                Origin => 'GaiaPick',
                              );

}

=back

=end __PRIVATE_METHODS__

=head1 FORMAT

The GaiaPick format is extremely simple. First there is an informational
header that describes the subsequent columns. This is a single line:

  # name   x y ra dec equinox angle   peak    background fwhm (X:Y)

(white space has been compressed in this description to remove the
need for line wrapping). The results of the "Pick Object" are then
written to the following lines, using up two lines per pick as
follows:

  # Sunday February 08 2004 - 16:43:59
  iras.sdf 153.3 151.5 00:42:45.757 +41:16:44.96 J2000 160.7 2.7 1.4 7.8 : 6.1

The first line indicates the date of the pick. The second line
contains the parameters of the source.

Currently the reader does not attempt to parse the first line in order
to derive the column information. The assumption is that the columns
are always in the same order.

=head1 SEE ALSO

The GAIA application can be obtained from Starlink (http://www.starlink.ac.uk).

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=cut

package Astro::Catalog::IO::UKIRTBS;

=head1 NAME

Astro::Catalog::IO::UKIRTBS - Old format used by UKIRT Bright Star catalogues

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::UKIRTBS->_read_catalog( \@lines );

=head1 DESCRIPTION

This class provides a read method for catalogs written in a format
used by the old C<ukstar> web interface to the SAO and Bright Star
catalogues. It is probable that this format has a real name and is a
historical format rather than a UKIRT-specific format but the history
of C<ukstar> and the associated catalogue files is not known to the
author of this module.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Catalog;
use Astro::Catalog::Star;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/ $VERSION /;

$VERSION = '4.35';

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog>
object containing the catalog entries.

 $cat = Astro::Catalog::IO::JCMT->_read_catalog( \@lines );

No options are supported.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  croak "Must supply catalogue contents as a reference to an array"
    unless ref($lines) eq 'ARRAY';

  # Go through each line and parse it
  my @stars;
  for my $l ( @$lines ) {
    # benchmarks suggest that substr is faster than an unpack
    my $bs = substr($l,0,8);
    my $ra = substr($l,9,12);
    my $dec = substr($l,21,12);
    my $rap = substr($l,34,4);
    my $decp = substr($l,40,4);
    my $mag = substr($l,46,4);
    my $type = substr($l,50);

    # Tidy the result
    chomp($type);
    $bs =~ s/^\s+//;

    # Create coordinate object
    my $c = new Astro::Coords( ra => $ra,
                               dec => $dec,
                               type => 'B1950',
                               name => $bs,
                               units => 'r',
                             );

    my $s = new Astro::Catalog::Star( coords => $c,
                                      id =>  $bs,
                                      spectype => $type,
                                      fluxes => new Astro::Fluxes(
                                        new Astro::Flux( $mag, 'mag', 'V') ),
                                    );
    push(@stars, $s);
  }

  # Create the catalog object
  return new Astro::Catalog( Stars => \@stars,
                             Origin => 'UKIRT BS Catalog',
                           );

}

=back

=head1 FORMAT

The catalog format uses fixed formatting (first column is column 1):

 Columns
  1-7     star id
 10-20    Right Ascension (presumed B1950). Radians
 21-32    Declination (presumed B1950). Radians
 33-38    "rap"  (unknown)
 39-44    "decp" (unknown)
 45-49    V Magnitude
 50-      Spectral type

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;

package Astro::FITS::HdrTrans::CURVE;

=head1 NAME

Astro::FITS::HdrTrans::CURVE - UKIRT CURVE translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::CURVE;

  %gen = Astro::FITS::HdrTrans::CURVE->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the CURVE camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UFTI.
use base qw/ Astro::FITS::HdrTrans::UFTI /;

use vars qw/ $VERSION /;

$VERSION = "1.60";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 FILE_FORMAT => "FITS",
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (

               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "CURVE".

=cut

sub this_instrument {
  return "CURVE";
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either Version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307, USA.

=cut

1;

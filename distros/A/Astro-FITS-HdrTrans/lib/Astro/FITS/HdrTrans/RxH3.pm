=head1 NAME

Astro::FITS::HdrTrans::RxH3 - translation class for RxH3

=cut

package Astro::FITS::HdrTrans::RxH3;

use warnings;
use strict;

our $VERSION = '1.62';

use base qw/Astro::FITS::HdrTrans::JCMT/;

my %CONST_MAP = (
);

my %UNIT_MAP = (
    OBSERVATION_MODE => 'OBS_TYPE',
    REST_FREQUENCY => 'FREQBAND',
    NUMBER_OF_FREQUENCIES => 'NFREQ',
);

__PACKAGE__->_generate_lookup_methods(\%CONST_MAP, \%UNIT_MAP);

=head1 METHODS

=over 4

=item B<this_instrument>

Returns "RxH3".

=cut

sub this_instrument {
    return 'RxH3';
}

1;

=back

=head1 COPYRIGHT

Copyright (C) 2018 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut

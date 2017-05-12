package Acme::MetaSyntactic::compass;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012052202';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::compass - Boxing the Compass

=head1 DESCRIPTION

The compass rose can be subdivided into 32 points, using the four
cardinal directions (north, east, south, and west) as the basis.
The naming of the 32 points is known as I<< boxing the compass >>.

In the Middle ages, sailors in the Mediterranean Sea used a system
based on eight winds, also subdividing their compass rose into 32 points.

This module provides the following sub themes:

=over 1

=item C<< direction/cardinal >>

The four main directions: north, east, south and west.

=item C<< direction/ordinal >>

The four direction halfway the cardinal directions: northeast, southeast,
southwest and northwest.

=item C<< direction >> aka C<< winds/principal >>

The eight best known compass points; a combination of the two subthemes
above.

=item C<< winds/half >>

The eight compass points found between the principal winds. From 
north_northeast to south_southwest and back.

=item C<< winds/quarter >>

The sixteen compass points found between the half winds and the quarter
winds. From north_by_east to south_by_west and back.

=item C<< winds >>

All 32 compass points.

=item C<< traditional/base >>

The eight winds used in the Middle ages: Tramontana, Greco, Levante, Scirocco,
Ostro, Libeccio, Ponente, and Maestro.

=item C<< traditional/half >>

The eight winds that fall halfway the base winds. From Greco_Tramontana to
Ostro_Libeccio and back.

=item C<< traditional/quarter >>

The sixteen winds that fall between the half winds and the base winds.
From Quarto_di_Tramontana_verso_Greco to Quarto_di_Ostro_verso_Libeccio
and back.

=item C<< traditional >>

All 32 traditional compass points.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2012 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


=cut

__DATA__
# default
direction
# names direction cardinal
north east south west
# names direction ordinal
northeast southeast southwest northwest
# names winds principal
north northeast east southeast south southwest west northwest
# names winds half
north_northeast east_northeast east_southeast south_southeast
south_southwest west_southwest west_northwest north_northwest
# names winds quarter
north_by_east northeast_by_north northeast_by_east east_by_north
east_by_south southeast_by_east southeast_by_south south_by_east
south_by_west southwest_by_south southwest_by_west west_by_south
west_by_north northwest_by_west northwest_by_north north_by_west
# names traditional base
Tramontana Greco Levante Scirocco Ostro Libeccio Ponente Maestro
# names traditional half
Greco_Tramontana Greco_Levante Levante_Scirocco Ostro_Scirocco
Ostro_Libeccio Ponente_Libeccio Maestro_Ponente Maestro_Tramontana
# names traditional quarter
Quarto_di_Tramontana_verso_Greco Quarto_di_Greco_verso_Tramontana
Quarto_di_Greco_verso_Levante Quarto_di_Levante_verso_Greco
Quarto_di_Levante_verso_Scirocco Quarto_to_Scirocco_verso_Levente
Quarto_di_Scirocco_verso_Ostro Quarto_di_Ostro_verso_Scirocco
Quarto_di_Ostro_verso_Libeccio Quarto_di_Libeccio_verso_Ostro
Quarto_di_Libeccio_verso_Ponente Quarto_di_Ponente_verso_Libeccio
Quarto_di_Ponente_verso_Maestro Quarto_di_Maestro_verso_Ponente
Quarto_di_Maestro_verso_Tramontana Quarto_di_Tramontana_verso_Maestro

package Acme::MetaSyntactic::charlies_angels;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012052101';
__PACKAGE__ -> init();

1;

=head1 NAME

Acme::MetaSyntactic::charlies_angels - Charlie's Angels

=head1 DESCRIPTION

Charlie's Angels was a popular detective series in the late 1970s and
early 1980s. This module provides a few (sub)themes: C<< first >>, 
C<< full >>, C<< actress >>, C<< male_character >> and C<< actor >>.
The first three themes can be subdivided into C<< season1 >> to 
C<< season5 >>.

Each of the five seasons had three Angels, and in total six Angels appeared:

 Actress                  Angel               Season(s)

 Kate Jackson             Sabrina Duncan        1-3
 Farrah Fawcett-Majors    Jill Munroe           1
 Jaclyn Smith             Kelly Garrett         1-5
 Cheryl Ladd              Kris Munroe           2-5
 Shelly Hack              Tiffany Welles        4
 Tanya Roberts            Julie Rogers          5

The C<< first >> subtheme (which is the default) lists the first names of
the Angels; C<< first/season1 >> lists the first names of the angles of
the first season, etc. The C<< full >> subtheme lists the full names of the
Angels. C<< actress >> lists the name of the actresses. Each of them can
be restricted to the certain season.

Two other main characters were male roles, and remained constant over the
series:

 Actor                    Character           Season(s)

 David Doyle              John Bosley         1-5
 John Forsythe            Charlie Townsend    1-5

The subthemes C<< actor >> and C<< male_character >> list them; they cannot
be subdivided into seasons.

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
first
# names first season1
Sabrina Jill Kelly
# names first season2
Sabrina Kelly Kris
# names first season3
Sabrina Kelly Kris
# names first season4
Kelly Kris Tiffany
# names first season5
Kelly Kris Julie
# names full season1
Sabrina_Duncan Jill_Munroe Kelly_Garrett
# names full season2
Sabrina_Duncan Kelly_Garrett Kris_Munroe
# names full season3
Sabrina_Duncan Kelly_Garrett Kris_Munroe
# names full season4
Kelly_Garrett Kris_Munroe Tiffany_Welles
# names full season5
Kelly_Garrett Kris_Munroe Julie_Rogers
# names actress season1
Kate_Jackson Farrah_Fawcett_Majors Jaclyn_Smith
# names actress season2
Kate_Jackson Jaclyn_Smith Cheryl_Ladd
# names actress season3
Kate_Jackson Jaclyn_Smith Cheryl_Ladd
# names actress season4
Jaclyn_Smith Cheryl_Ladd Shelley_Hack
# names actress season5
Jaclyn_Smith Cheryl_Ladd Tanya_Roberts
# names male_characters
John_Bosley Charlie_Townsend
# names actors
David_Doyle John_Forsythe

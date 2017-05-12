package Acme::MetaSyntactic::beatles;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012051701';
__PACKAGE__ -> init();

1;

=head1 NAME

Acme::MetaSyntactic::beatles - Singers from the 1960s British rock & roll group.

=head1 DESCRIPTION

The Beatles were to music what LISP was the programming languages.

This module contains four (sub)themes related to their names:
C<< first/standard >>, containing
the four first names (John, Paul, George, Ringo) of what we typically 
consider to be the four Beatles. C<< full/standard >> contain the full
names of the fab four: John Lennon, Paul McCartney, George Harrison, and
Ringo Starr. However, in the early years of the band, the drummer was
Pete Best. Hence the additional themes C<< first/early >> and C<< full/early >>,
which swaps Ringo Starr for Pete Best. The default theme is
C<< first/standard >>.

A fifth theme is C<< albums >>, containing the names of the 12 albums that
are considered the "core" albums of The Beatles.

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
first/standard
# names first standard
John Paul George Ringo
# names full standard
John_Lennon Paul_McCartney George_Harrison Ringo_Starr
# names first early
John Paul George Pete
# names full early
John_Lennon Paul_McCartney George_Harrison Pete_Best
# names albums
Please_Please_Me
With_The_Beatles
A_Hard_Day_s_Night
Beatles_for_Sale
Help
Rubber_Soul
Revolver
Sgt_Pepper_s_Lonely_Hearts_Club_Band
The_Beatles
Yellow_Submarine
Abbey_Road
Let_It_Be

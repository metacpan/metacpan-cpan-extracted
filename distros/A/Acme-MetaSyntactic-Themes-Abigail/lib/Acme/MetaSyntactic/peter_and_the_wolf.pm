package Acme::MetaSyntactic::peter_and_the_wolf;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2013072602';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::peter_and_the_wolf - Characters from Peter and the Wolf

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme lists the character from the
story I<< Peter and the Wolf >>, a Russian childrens story written
in 1936 by Sergei Prokofiev. Traditionally, the story is told by a
narrator, with the help of an orchestra. Each character has its own
particular instrument.

The default subtheme is C<< characters >>, which gives you the
characters of the story. The subtheme C<< instruments >> give you
the instruments of the characters.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2013 by Abigail.

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
characters
# names characters
bird duck cat wolf peter grandfather hunters
# names instruments
flute oboe clarinet french_horns string_instruments bassoon woodwind

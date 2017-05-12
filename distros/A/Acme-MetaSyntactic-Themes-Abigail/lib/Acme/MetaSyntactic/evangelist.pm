package Acme::MetaSyntactic::evangelist;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::Locale;
our @ISA = qw [Acme::MetaSyntactic::Locale];

our $VERSION = '2012053001';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::evangelist - Gospel authors

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme provides the names of the four
evangelists, localized in 19 different languages and dialects.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

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
en
# names en
Matthew Mark Luke John
# names cs
Matous Marek Lukas Jan
# names de
Matthaus Markus Lukas Johannes 
# names du
Matheus Marcus Lucas Johannes
# names fr
Matthieu Marc Luc Jean
# names fi
Matteus Markus Luukas Johannes
# names hr
Matej Marko Luka Ivan
# names hu
Mate Mark Lukacs Janos
# names it
Matteo Marco Luca Giovanni
# names la
Mattheus Marcus Lucas Ioannes
# names li
Matheus Marcus Lucas Johannes
# names nds
Matthaus Markus Lukas Johannes
# names nrm
Maquieu Mar Luc Jean
# names pl
Marek Mateusz Lukasz Jan
# names pt
Mateus Marcos Lucas Joao
# names ro
Matei Marcu Luca Ioan
# names sl
Matej Marko Luka Janez
# names sv
Matteus Markus Lukas Johannes
# names sw
Marko Mathayo Luka Yohane

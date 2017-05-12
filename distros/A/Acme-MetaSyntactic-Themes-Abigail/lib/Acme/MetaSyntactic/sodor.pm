package Acme::MetaSyntactic::sodor;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012051701';
__PACKAGE__ -> init();

1;

=head1 NAME

Acme::MetaSyntactic::sodor - Characters from The Railway Series

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme contains the characters from
I<< The Railway Series >>, also known as I<< Thomas the Tank Engine >>
and friends. The Railway Series is situated on the fictional island
I<< Sodor >>, hence the name of the theme.

The characters in this theme are based on the books; this may differ
slightly from the TV series.

This module contains a couple of (sub) themes:

=over 1

=item C<< steam_engines >>

This is the default theme, and lists the main steam engines in the books.

=item C<< diesel_engines >>

This subtheme lists the important diesel engines from the books.

=item C<< rolling_stock >>

This subtheme lists the important rolling stock.

=item C<< narrow gauge >>

This subtheme lists the engines from the narrow gauge I<< Skarloey Railway >>.

=item C<< humans >>

A subtheme just for the I<< Fat Controller >>

=item C<< other >>

A couple of other important, non-railroad, characters.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=head1 BUGS

Minor characters are not listed.

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
steam_engines
# names steam_engines
Thomas Edward Henry Gordon James Percy Toby Duck Donald Douglas Oliver
Bill Ben
# names diesel_engines
Diesel Daisy BoCo Bear Mavis Pip Emma
# names rolling_stock
Annie Clarabel Henrietta
# names narrow_gauge
Skarloey Rheneas Sir_Handel Peter_Sam Duncan
# names humans
Fat_Controller
# names other
Terence Bertie Traction_Engine Harold

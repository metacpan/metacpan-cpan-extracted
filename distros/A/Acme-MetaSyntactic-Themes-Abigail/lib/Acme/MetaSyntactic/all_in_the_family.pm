package Acme::MetaSyntactic::all_in_the_family;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::List;
our @ISA = qw [Acme::MetaSyntactic::List];

our $VERSION = '2012060202';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::all_in_the_family - The main characters.

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme lists the main characters
of the series C<< All In The Family >>, whose original ran from
1971 to 1979.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<< Acme::MetaSyntactic::List >>,
L<< http://www.imdb.com/title/tt0066626/combined >>.

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
# names
Archie_Bunker Edith_Bunker Gloria_Stivic Michael_Stivic

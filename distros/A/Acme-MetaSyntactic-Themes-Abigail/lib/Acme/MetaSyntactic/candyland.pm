package Acme::MetaSyntactic::candyland;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012060301';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::candyland - Candyland Characters

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme lists the characters from
the classical game of I<< Candyland >>. Althought the game itself
dates from the 1940s, characters were first introduced in the 1984
edition. Updates to the character names where made in 2002 and 2010.
Hence, three subthemes:

=over 1

=item C<< edition_1984 >>

The default sub theme. This was the year the characters were first
introduced.

=item C<< edition_2002 >>

This edition saw the first change in the set of characters.

=item C<< edition_2010 >>

The edition saw the second change in the set of characters.

=back

I<< Candyland >> is published by I<< Hasbro >>.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>,
L<< http://www.hasbro.com/ >>.

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
edition_1984
# names edition_1984
The_Kids The_Gingerbread_People Mr_Mint Gramma_Nutt King_Kandy Jolly
Plumpy Princess_Lolly Queen_Frostine Lord_Licorice
Gloppy_the_Molasses_Monster
# names edition_2002
The_Kids The_Gingerbread_People Mr_Mint Gramma_Nutt King_Kandy Jolly
Mama_Ginger_Tree Lolly Princess_Frostine Lord_Licorice
Gloppy_the_Molasses_Monster
# names edition_2002
The_Kids The_Gingerbread_People Duke_of_Swirl Gramma_Gooey King_Kandy
Cupcakes Princess_Lolly Princess_Frostine Lord_Licorice
Gloppy_the_Chocolate_Monster

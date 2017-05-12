package Acme::MetaSyntactic::famous_five;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012060102';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::famous_five - One of the Enid Blyton series.

=head1 DESCRIPTION

The I<< Famous Five >> is a series of childrens book, written by 
Enid Blyton between 1942 and 1962. There are 21 books, describing
the adventures of four children and their dog.

There are four subthemes:

=over 1

=item C<< characters/major >>

The default theme, with the names of the major characters, including
the dog.

=item C<< characters/minor >>

The minor characters, but important enough to appear at least a few
books.

=item C<< characters >>

The combination of the lists above.

=item C<< books >>

The names of the 21 books.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

There have been books written in the series in French and German, long
after the original series. They have not been considered for inclusion.

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
characters/major
# names characters major
Julian Dick George Anne Timmy
# names characters minor
Aunt_Fanny Uncle_Quentin Joanna Jo
# names books
Five_on_a_Treasure_Island           Five_Go_Adventuring_Again
Five_Run_Away_Together              Five_Go_to_Smugglers_Top
Five_Go_Off_in_a_Caravan            Five_on_Kirrin_Island_Again
Five_Go_Off_to_Camp                 Five_Get_Into_Trouble
Five_Fall_Into_Adventure            Five_on_a_Hike_Together
Five_Have_a_Wonderful_Time          Five_Go_Down_to_the_Sea
Five_Go_to_Mystery_Moor             Five_Have_Plenty_of_Fun
Five_on_a_Secret_Trail              Five_Go_to_Billycock_Hill
Five_Get_Into_a_Fix                 Five_on_Finniston_Farm
Five_Go_to_Demons_Rocks             Five_Have_a_Mystery_to_Solve
Five_Are_Together_Again


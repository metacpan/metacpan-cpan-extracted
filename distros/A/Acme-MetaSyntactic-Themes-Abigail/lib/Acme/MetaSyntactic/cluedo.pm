package Acme::MetaSyntactic::cluedo;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012060101';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::cluedo - Characters, rooms and weapons from Cluedo

=head1 DESCRIPTION

I<< Cluedo >> (or I<< Clue >> as it's known in North America), is a famous
detective like board games, where the players have to determine who killed
Dr. Black, which weapon was used, and in which room the murder did happen.

There are three subthemes:

=over 1

=item C<< suspects >>

This is the default theme, and lists the possible murderers.

=item C<< weapon >>

The theme that lists the weapons that could have been used to
kill Dr. Black.

=item C<< room >>

Lists the rooms of the mansion of Dr. Black in which the murder
could have taken place.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

This module uses the British spelling. So, we have I<< Miss Scarlett >>
instead of I<< Miss Scarlet >>; I<< Reverend Green >> instead of 
I<< Mr. Green >>, a I<< dagger >> instead of a I<< knife >>, a
I<< revolver >> instead of a I<< pistol >>, a I<< spanner >> instead
of a I<< wrench >>, and the game itself is called I<< Cluedo >> instead
of I<< Clue >>.

While the I<< Cellar >> is on the board, it's not an actual location
where the murder could have happened, and as such, isn't part of the
theme.

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
suspects
# names suspects
Miss_Scarlett Colonel_Mustard Mrs_White
Reverend_Green Mrs_Peacock Professor_Plum
# names weapons
Candlestick Dagger Lead_Pipe Revolver Rope Spanner 
# names rooms
Kitchen Ballroom Conservatory Billiard_Room Library Study Hall Lounge
Dining_Room

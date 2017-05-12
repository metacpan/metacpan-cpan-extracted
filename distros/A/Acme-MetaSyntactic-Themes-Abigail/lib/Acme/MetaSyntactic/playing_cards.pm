package Acme::MetaSyntactic::playing_cards;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::List;
our @ISA = qw [Acme::MetaSyntactic::List];

our $VERSION = '2013072601';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::playing_cards - Standard 52 deck

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme names the cards of a standard
deck of 52 playing cards, with suits I<< Clubs >>, I<< Diamonds >>,
I<< Hearts >>, and I<< Spades >>. Card ranks are I<< Ace >>, I<< Two >>,
I<< Three >>, I<< Four >>, I<< Five >>, I<< Six >>, I<< Seven >>, I<< Eight >>,
I<< Nine >>, I<< Ten >>, I<< Jack >>, I<< Queen >>, and I<< King >>.

Alternative names like I<< Deuce >> for I<< Two >>, or I<< Knave >> instead
of I<< Jack >>, are not supported.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<< Acme::MetaSyntactic::List >>

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
# names
Ace_of_Clubs Two_of_Clubs Three_of_Clubs Four_of_Clubs Five_of_Clubs
Six_of_Clubs Seven_of_Clubs Eight_of_Clubs Nine_of_Clubs Ten_of_Clubs
Jack_of_Clubs Queen_of_Clubs King_of_Clubs
Ace_of_Diamonds Two_of_Diamonds Three_of_Diamonds Four_of_Diamonds
Five_of_Diamonds Six_of_Diamonds Seven_of_Diamonds Eight_of_Diamonds
Nine_of_Diamonds Ten_of_Diamonds
Jack_of_Diamonds Queen_of_Diamonds King_of_Diamonds
Ace_of_Hearts Two_of_Hearts Three_of_Hearts Four_of_Hearts Five_of_Hearts
Six_of_Hearts Seven_of_Hearts Eight_of_Hearts Nine_of_Hearts Ten_of_Hearts
Jack_of_Hearts Queen_of_Hearts King_of_Hearts
Ace_of_Spades Two_of_Spades Three_of_Spades Four_of_Spades Five_of_Spades
Six_of_Spades Seven_of_Spades Eight_of_Spades Nine_of_Spades Ten_of_Spades
Jack_of_Spades Queen_of_Spades King_of_Spades

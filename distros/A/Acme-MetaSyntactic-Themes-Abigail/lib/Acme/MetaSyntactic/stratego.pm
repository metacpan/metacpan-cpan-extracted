package Acme::MetaSyntactic::stratego;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::List;
our @ISA = qw [Acme::MetaSyntactic::List];

our $VERSION = '2012060701';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::stratego - Stratego pieces

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme lists the pieces from the
classical boardgame I<< Stratego >>. The game was created by
I<< Mademoiselle Hermance Edan >> in 1908, and it was named 
I<< L'attaque >>. Currently, the game is published by I<< Jumbo >>
and I<< Hasbro >>. I<< Stratego >> has roots in the game of 
I<< Shou Dou Qi >>.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

In some editions, the I<< miner >> is known as a I<< sapper >>.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>,
L<< Acme::MetaSyntactic::shou_dou_qi >>, L<< http://www.stratego.com/ >>.

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
flag bomb spy scout miner sergeant lieutenant captain major colonel
general marshall

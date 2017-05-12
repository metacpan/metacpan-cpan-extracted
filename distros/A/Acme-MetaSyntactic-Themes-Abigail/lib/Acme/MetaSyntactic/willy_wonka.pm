package Acme::MetaSyntactic::willy_wonka;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::List;
our @ISA = qw [Acme::MetaSyntactic::List];

our $VERSION = '2012060103';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::willy_wonka - Charlie and the Chocolate Factory

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme lists the main characters
from the 1964 book, I<< Charlie and the Chocolate Factory >>, written
by I<< Roald Dahl >>.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<< Acme::MetaSyntactic::List >>,
L<< http://www.roalddahl.com/ >>.

=head1 NOTES

If you are only familiar with the movies, the name Arthur Slugworth may 
not say you much; but he plays a more prominent role in the book.

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
Charlie_Bucket Willy_Wonka Grandpa_Joe Veruca_Salt Mike_Teavee
Violet_Beauregarde Augustus_Gloop Arthur_Slugworth

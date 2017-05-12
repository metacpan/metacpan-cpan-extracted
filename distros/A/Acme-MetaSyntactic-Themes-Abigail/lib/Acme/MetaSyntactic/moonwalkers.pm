package Acme::MetaSyntactic::moonwalkers;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::List;
our @ISA = qw [Acme::MetaSyntactic::List];

our $VERSION = '2013072602';

=head1 NAME

Acme::MetaSyntactic::moonwalkers - People who have walked on the moon.

=head1 DESCRIPTION

Between 1969 and 1972, the United States send six manned missions to
the moon. Twelve people have walked on the moon.

=head2 Moonwalkers

The following people have walked on the moon:

=cut

__PACKAGE__ -> init ({
    names  =>  join ' ',
               map {s/__+/_/g; $_}
               map {Acme::MetaSyntactic::RemoteList::tr_nonword ($_)}
               map {Acme::MetaSyntactic::RemoteList::tr_accent  ($_)}
               map {/^\s+(\S+\s+(?:\w\.\s+)?\S+)/ ? $1 : ()}
               split /\n/ => <<'=cut' });

=pod

  Neil Armstrong            Apollo 11      July 21, 1969
  Buzz Aldrin

  Pete Conrad               Apollo 12      November 19 & 20, 1969
  Alan Bean

  Alan Shepard              Apollo 14      February 5 & 6, 1971  
  Edgar Mitchell

  David Scott               Apollo 15      July 31, August 1 & 2, 1971
  James Irwin   

  John W. Young             Apollo 16      April 21, 22 & 23, 1972
  Charles Duke  

  Eugene Cernan             Apollo 17      December 12, 13 & 14, 1972
  Harrison Schmitt

=cut

=pod

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

=head1 SEE ALSO

L<Acme::MetaSyntactic>.

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

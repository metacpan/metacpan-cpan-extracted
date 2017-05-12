package Acme::CPANAuthors::Dutch;

use 5.006;
use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009102802';

use Acme::CPANAuthors::Register (
    '' => '',
);


1;

__END__

=head1 NAME

Acme::CPANAuthors::Dutch - Cheese heads and pot smokers.

=head1 SYNOPSIS

 use Acme::CPANAuthors;

 my $authors = Acme::CPANAuthors -> new ('Dutch');

=head1 DESCRIPTION

The Netherlands is full of people smoking pot, wearing clogs and
living in wind mills. We don't do Perl.

=head1 BUGS

None.

=head1 TODO

The Netherlands is full. No new people accepted.

=head1 SEE ALSO

The rest of the world.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Acme--CPANAuthors--Dutch.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail.

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

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut

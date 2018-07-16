package Alien::LibXML;
use strict;
use warnings;
use parent 'Alien::Base';
our $VERSION = '0.004';

__END__

=pod

=encoding utf8

=head1 NAME

Alien::LibXML - install the C libxml2 library on your system

=head1 SYNOPSIS

   use 5.010;
   use strict;
   use Alien::LibXML;
   
   my $alien = Alien::LibXML->new;
   say $alien->libs;
   say $alien->cflags;

=head1 DESCRIPTION

Hopefully at some point, L<XML::LibXML>'s installation scripts might use
Alien::LibXML to locate or install the C libxml2 library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT, LICENCE AND DISCLAIMER OF WARRANTIES

Copyright (c) 2012-2014, 2018 Toby Inkster.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


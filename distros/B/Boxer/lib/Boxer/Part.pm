package Boxer::Part;

=encoding UTF-8

=head1 NAME

Boxer::Part - software component

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use namespace::autoclean 0.16;
use autodie;

use Moo;
use MooX::StrictConstructor;

=head1 VERSION

Version v1.3.0

=cut

our $VERSION = version->declare("v1.3.0");

=head1 DESCRIPTION

Outside the box is a World of software,
consisting of parts.

B<Boxer::Part> represents a part of a <Boxer::World>.

=head1 SEE ALSO

L<Boxer>.

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

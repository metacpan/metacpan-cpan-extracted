package Boxer::World;

=encoding UTF-8

=head1 NAME

Boxer::World - set of software available to install

=cut

use v5.14;
use utf8;
use strictures 2;
use Role::Commons -all;
use namespace::autoclean 0.16;
use autodie;

use Moo;
use MooX::StrictConstructor;
use Types::Standard qw( ArrayRef InstanceOf );
with qw(MooX::Role::Logger);

=head1 VERSION

Version v1.4.0

=cut

our $VERSION = "v1.4.0";

=head1 DESCRIPTION

Outside the box is a world of software.

B<Boxer::World> is a class describing a collection of software
available for installation into (or as) an operating system.

=head1 SEE ALSO

L<Boxer>.

=cut

has parts => (
	is       => 'ro',
	isa      => ArrayRef [ InstanceOf ['Boxer::Part'] ],
	required => 1,
);

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

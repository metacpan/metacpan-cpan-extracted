package Boxer::Part::Reclass;

=encoding UTF-8

=head1 NAME

Boxer::Part::Reclass - software component as a reclass node or class

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use autodie;

use Moo;
extends 'Boxer::Part';
use Types::Standard qw(Str Maybe ArrayRef HashRef);
use Types::TypeTiny qw(StringLike);

use namespace::clean;

=head1 VERSION

Version v1.1.5

=cut

our $VERSION = version->declare("v1.1.5");

=head1 DESCRIPTION

Outside the box is a World of software,
consisting of parts.

B<Boxer::Part::Reclass::Node> represents a part of a <Boxer::World>,
represented as a B<reclass> node or class.

=head1 SEE ALSO

L<Boxer>.

=cut

has id => (
	is  => 'ro',
	isa => Str,
);

has classes => (
	is  => 'ro',
	isa => Maybe [ ArrayRef [Str] ],
);

has doc => (
	is  => 'ro',
	isa => HashRef,
);

has pkg => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has pkg_auto => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has pkg_avoid => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has pkg_nonfree => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has pkg_nonfree_auto => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has bug => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has tweak => (
	is  => 'ro',
	isa => ArrayRef [Str],
);

has epoch => (
	is  => 'ro',
	isa => Maybe [StringLike],
);

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

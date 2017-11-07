package Boxer::World::Flat;

=encoding UTF-8

=head1 NAME

Boxer::World::Reclass - software for single use case

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use autodie;

use Moo;
extends 'Boxer::World';
use Types::Standard qw(Maybe Bool Tuple);
use Types::TypeTiny qw(StringLike ArrayLike);

use namespace::clean;

=head1 VERSION

Version v1.1.7

=cut

our $VERSION = version->declare("v1.1.7");

=head1 DESCRIPTION

Outside the box is a world of software.

B<Boxer::World::Reclass> is a class describing a collection of software
available for installation into (or as) an operating system.

=head1 SEE ALSO

L<Boxer>.

=cut

has parts => (
	is      => 'ro',
	isa     => Tuple [],
	default => sub { [] },
);

has node => (
	is       => 'ro',
	isa      => StringLike,
	required => 1,
);

has epoch => (
	is  => 'ro',
	isa => Maybe [StringLike],
);

has pkgs => (
	is       => 'ro',
	isa      => ArrayLike,
	required => 1,
);

has pkgs_auto => (
	is       => 'ro',
	isa      => ArrayLike,
	required => 1,
);

has pkgs_avoid => (
	is       => 'ro',
	isa      => ArrayLike,
	required => 1,
);

has tweaks => (
	is       => 'ro',
	isa      => ArrayLike,
	required => 1,
);

has pkgdesc => (
	is       => 'ro',
	isa      => StringLike,
	required => 1,
);

has tweakdesc => (
	is       => 'ro',
	isa      => StringLike,
	required => 1,
);

has nonfree => (
	is       => 'ro',
	isa      => Bool,
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

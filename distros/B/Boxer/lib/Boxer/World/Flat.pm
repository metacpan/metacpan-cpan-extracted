package Boxer::World::Flat;

=encoding UTF-8

=head1 NAME

Boxer::World::Flat - software for single use case

=cut

use v5.14;
use utf8;
use strictures 2;
use Role::Commons -all;
use namespace::autoclean 0.16;
use autodie;

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::World);

use Types::Standard qw( Maybe Bool Tuple );
use Types::TypeTiny qw( StringLike ArrayLike );

=head1 VERSION

Version v1.4.0

=cut

our $VERSION = "v1.4.0";

=head1 DESCRIPTION

Outside the box is a world of software.

B<Boxer::World::Flat> is a class describing a collection of software
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

sub as_file
{
	my ( $self, $file, $oldstyle ) = @_;

	my $pkgs       = join( ',',      sort @{ $self->pkgs } );
	my $pkgs_avoid = join( ',',      sort @{ $self->pkgs_avoid } );
	my $pkgs_auto  = join( ',',      sort @{ $self->pkgs_auto } );
	my $tweaks     = join( ";\\\n ", @{ $self->tweaks } );

	my $pkglist = join( ' ', sort @{ $self->pkgs } );
	$pkglist .= " \\\n ";
	$pkglist .= join( ' ', sort map { $_ . '-' } @{ $self->pkgs_avoid } );
	my $pkgautolist = join( ' ', sort @{ $self->pkgs_auto } );

	my $tweaks_perl = $tweaks;
	$tweaks_perl =~ s,chroot\s+/target\s+,,g;
	$tweaks_perl =~ s,/target/,/,g;

	# TODO: maybe move below (or only $''{ part?) to reclass parser
	$tweaks_perl =~ s/\\\K''(?=n)|\$\K''(?=\{)//g;

	my %vars = (
		node        => $self->node,
		suite       => $self->epoch,
		pkgs        => $pkgs,
		pkgs_avoid  => $pkgs_avoid,
		pkgs_auto   => $pkgs_auto,
		pkgdesc     => $self->pkgdesc,
		pkglist     => $pkglist,
		tweakdesc   => $self->tweakdesc,
		tweaks      => $tweaks,
		tweaks_perl => $tweaks_perl,
		tweaklist   => $tweaks,
		pkgautolist => $pkgautolist,
		nonfree     => $self->nonfree,
	);

	# TODO: Drop oldstyle templating format
	# (oldstyle preseed templates expect perl tweaks in regular tweaks string)
	if ($oldstyle) {
		my %altvars = %vars;
		$altvars{tweaklist} = $tweaks_perl;
		$file->create( \%altvars );
	}
	else {
		$file->create( \%vars );
	}

	1;
}

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

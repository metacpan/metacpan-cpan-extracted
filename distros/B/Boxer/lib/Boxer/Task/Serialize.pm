package Boxer::Task::Serialize;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use autodie;

use Path::Tiny;
use File::ShareDir qw(dist_dir);
use Boxer::File::WithSkeleton;

use Moo;
use Types::Standard qw( Bool Maybe Str Undef InstanceOf );
use Types::Path::Tiny qw( Dir File Path );
use Boxer::Types qw( SkelDir );
extends 'Boxer::Task';

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.2.0

=cut

our $VERSION = version->declare("v1.2.0");

has world => (
	is       => 'ro',
	isa      => InstanceOf ['Boxer::World::Reclass'],
	required => 1,
);

has skeldir => (
	is     => 'ro',
	isa    => Maybe [SkelDir],
	coerce => 1,
);

has infile => (
	is     => 'ro',
	isa    => File,
	coerce => File->coercion,
);

has altinfile => (
	is     => 'ro',
	isa    => File,
	coerce => File->coercion,
);

has outdir => (
	is     => 'ro',
	isa    => Dir,
	coerce => Dir->coercion,
);

has outfile => (
	is     => 'ro',
	isa    => Path,
	coerce => Path->coercion,
);

has altoutfile => (
	is     => 'ro',
	isa    => Path,
	coerce => Path->coercion,
);

has node => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has nonfree => (
	is       => 'ro',
	isa      => Bool,
	required => 1,
	default  => sub {0},
);

sub run
{
	my $self = shift;

	my $world = $self->world->flatten( $self->node, $self->nonfree, );

	my $pkgs       = join( ',',      sort @{ $world->pkgs } );
	my $pkgs_avoid = join( ',',      sort @{ $world->pkgs_avoid } );
	my $pkgs_auto  = join( ',',      sort @{ $world->pkgs_auto } );
	my $tweaks     = join( ";\\\n ", @{ $world->tweaks } );

	my $pkglist = join( ' ', sort @{ $world->pkgs } );
	$pkglist .= " \\\n ";
	$pkglist .= join( ' ', sort map { $_ . '-' } @{ $world->pkgs_avoid } );
	my $pkgautolist = join( ' ', sort @{ $world->pkgs_auto } );

	my $tweaks_perl = $tweaks;
	$tweaks_perl =~ s,chroot\s+/target\s+,,g;
	$tweaks_perl =~ s,/target/,/,g;

	# TODO: maybe move below (or only $''{ part?) to reclass parser
	$tweaks_perl =~ s/\\\K''(?=n)|\$\K''(?=\{)//g;

	my %vars = (
		node        => $self->node,
		suite       => $world->epoch,
		pkgs        => $pkgs,
		pkgs_avoid  => $pkgs_avoid,
		pkgs_auto   => $pkgs_auto,
		pkgdesc     => $world->pkgdesc,
		pkglist     => $pkglist,
		tweakdesc   => $world->tweakdesc,
		tweaks      => $tweaks,
		tweaks_perl => $tweaks_perl,
		tweaklist   => $tweaks,
		pkgautolist => $pkgautolist,
		nonfree     => $self->nonfree,
	);
	my %altvars = %vars;
	$altvars{tweaklist} = $tweaks_perl;

	Boxer::File::WithSkeleton->new(
		basename      => 'preseed.cfg',
		skeleton_dir  => $self->skeldir,
		skeleton_path => $self->infile,
		file_dir      => $self->outdir,
		file_path     => $self->outfile,
		vars          => \%vars,
	)->create;

	Boxer::File::WithSkeleton->new(
		basename      => 'script.sh',
		skeleton_dir  => $self->skeldir,
		skeleton_path => $self->altinfile,
		file_dir      => $self->outdir,
		file_path     => $self->altoutfile,
		vars          => \%altvars,
	)->create;
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

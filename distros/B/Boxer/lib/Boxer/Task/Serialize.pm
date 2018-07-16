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

Version v1.1.8

=cut

our $VERSION = version->declare("v1.1.8");

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

	my $pkglist = join( ' ', sort @{ $world->pkgs } );
	$pkglist .= " \\\n ";
	$pkglist .= join( ' ', sort map { $_ . '-' } @{ $world->pkgs_avoid } );
	my $pkgautolist = join( ' ',      sort @{ $world->pkgs_auto } );
	my $tweaklist   = join( ";\\\n ", @{ $world->tweaks } );

	my %vars = (
		node        => $self->node,
		suite       => $world->epoch,
		pkgdesc     => $world->pkgdesc,
		pkglist     => $pkglist,
		tweakdesc   => $world->tweakdesc,
		tweaklist   => $tweaklist,
		pkgautolist => $pkgautolist,
	);

	Boxer::File::WithSkeleton->new(
		basename      => 'preseed.cfg',
		skeleton_dir  => $self->skeldir,
		skeleton_path => $self->infile,
		file_dir      => $self->outdir,
		file_path     => $self->outfile,
		vars          => \%vars,
	)->create;

	my %altvars = %vars;
	$altvars{tweaklist} =~ s,chroot\s+/target\s+,,g;
	$altvars{tweaklist} =~ s,/target/,/,g;

	# TODO: maybe move below (or only $''{ part?) to reclass parser
	$altvars{tweaklist} =~ s/\\\K''(?=n)|\$\K''(?=\{)//g;

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

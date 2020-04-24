package Boxer::Task::Serialize;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;
use autodie;

use Path::Tiny;
use File::ShareDir qw(dist_dir);
use Boxer::File::WithSkeleton;

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::Task);

use Types::Standard qw( Bool Maybe Str Undef InstanceOf );
use Types::Path::Tiny qw( Dir File Path );
use Boxer::Types qw( SkelDir SerializationList );

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.2

=cut

our $VERSION = "v1.4.2";

has world => (
	is       => 'ro',
	isa      => InstanceOf ['Boxer::World'],
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
	coerce => 1,
);

has altinfile => (
	is     => 'ro',
	isa    => File,
	coerce => 1,
);

has outdir => (
	is     => 'ro',
	isa    => Dir,
	coerce => 1,
);

has outfile => (
	is     => 'ro',
	isa    => Path,
	coerce => 1,
);

has altoutfile => (
	is     => 'ro',
	isa    => Path,
	coerce => 1,
);

has node => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has format => (
	is       => 'ro',
	isa      => SerializationList,
	coerce   => 1,
	required => 1,
);

has nonfree => (
	is       => 'ro',
	isa      => Bool,
	required => 1,
	default  => sub {0},
);

sub run ($self)
{
	my $world = $self->world->map( $self->node, $self->nonfree, );

	if ( grep( /^preseed$/, @{ $self->format } ) ) {
		my @args = (
			basename      => 'preseed.cfg',
			skeleton_dir  => $self->skeldir,
			skeleton_path => $self->infile,
			file_dir      => $self->outdir,
			file_path     => $self->outfile,
		);
		$self->_logger->info(
			'Serializing to preseed',
			$self->_logger->is_debug() ? {@args} : (),
		);
		my $file = Boxer::File::WithSkeleton->new(@args);
		$world->as_file($file);
	}

	if ( grep( /^script$/, @{ $self->format } ) ) {
		my @args = (
			basename      => 'script.sh',
			skeleton_dir  => $self->skeldir,
			skeleton_path => $self->altinfile,
			file_dir      => $self->outdir,
			file_path     => $self->altoutfile,
		);
		$self->_logger->info(
			'Serializing to script',
			$self->_logger->is_debug() ? {@args} : (),
		);
		my $file = Boxer::File::WithSkeleton->new(@args);
		$world->as_file( $file, 1 );
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

package Boxer::File::WithSkeleton;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;

use Path::Tiny;
use Template::Tiny;
use File::ShareDir qw(dist_dir);

use Moo;
use MooX::StrictConstructor;

use Types::Standard qw(Maybe);
use Types::TypeTiny qw(HashLike);
use Types::Path::Tiny qw(Dir File Path);
use Boxer::Types qw(SkelDir Basename);

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

# permit callers to sloppily pass undefined values
sub BUILDARGS ( $class, %args )
{
	delete @args{ grep !defined( $args{$_} ), keys %args };
	return {%args};
}

has basename => (
	is  => 'ro',
	isa => Basename,
);

has file => (
	is  => 'lazy',
	isa => Basename,

	default => sub ($self) {
		if ( $self->basename ) {
			return $self->basename;
		}
		elsif ( $self->skeleton_suffix ) {
			return $self->skeleton_path->basename( $self->skeleton_suffix );
		}
	},
);

has file_path => (
	is       => 'lazy',
	isa      => Path,
	required => 1,
	default  => sub ($self) {
		if ( $self->file_dir and $self->file ) {
			return $self->file_dir->child( $self->file );
		}
	},
);

has file_dir => (
	is      => 'lazy',
	isa     => Dir,
	default => sub { path('.') },
);

has skeleton => (
	is      => 'lazy',
	isa     => Basename,
	default => sub ($self) {
		if (    $self->basename
			and $self->skeleton_dir
			and $self->skeleton_suffix )
		{
			return $self->skeleton_dir->child(
				$self->basename . $self->skeleton_suffix )->basename;
		}
	},
);

has skeleton_path => (
	is       => 'lazy',
	isa      => File,
	required => 1,
	default  => sub ($self) {
		if ( $self->skeleton_dir and $self->skeleton ) {
			return $self->skeleton_dir->child( $self->skeleton );
		}
	},
);

has skeleton_dir => (
	is      => 'lazy',
	isa     => SkelDir,
	default => sub { path( dist_dir('Boxer'), 'skel' ) },
);

has skeleton_suffix => (
	is      => 'ro',
	isa     => Basename,
	default => '.in',
);

sub create ( $self, $vars )
{
	my $template = Template::Tiny->new(
		TRIM => 1,
	);

	my $content = '';
	$template->process(
		\$self->skeleton_path->slurp,
		$vars,
		\$content
	);
	$self->file_path->spew( $content . "\n" );
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

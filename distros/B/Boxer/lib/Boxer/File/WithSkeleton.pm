package Boxer::File::WithSkeleton;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;

use Path::Tiny;
use Template::Tiny;
use File::ShareDir qw(dist_dir);

use Moo;
use Types::Standard qw(Maybe);
use Types::TypeTiny qw(HashLike);
use Types::Path::Tiny qw(Dir File Path);
use Boxer::Types qw(SkelDir Basename);

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.1.8

=cut

our $VERSION = version->declare("v1.1.8");

# permit callers to sloppily pass undefined values
sub BUILDARGS
{
	my ( $class, %args ) = @_;
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

	default => sub {
		if ( $_[0]->basename ) {
			return $_[0]->basename;
		}
		elsif ( $_[0]->skeleton_suffix ) {
			return $_[0]->skeleton_path->basename( $_[0]->skeleton_suffix );
		}
	},
);

has file_path => (
	is       => 'lazy',
	isa      => Path,
	required => 1,
	default  => sub {
		if ( $_[0]->file_dir and $_[0]->file ) {
			return $_[0]->file_dir->child( $_[0]->file );
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
	default => sub {
		if (    $_[0]->basename
			and $_[0]->skeleton_dir
			and $_[0]->skeleton_suffix )
		{
			return $_[0]->skeleton_dir->child(
				$_[0]->basename . $_[0]->skeleton_suffix )->basename;
		}
	},
);

has skeleton_path => (
	is       => 'lazy',
	isa      => File,
	required => 1,
	default  => sub {
		if ( $_[0]->skeleton_dir and $_[0]->skeleton ) {
			return $_[0]->skeleton_dir->child( $_[0]->skeleton );
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

has vars => (
	is       => 'ro',
	isa      => HashLike,
	required => 1,
);

sub create
{
	my $self = shift;

	my $template = Template::Tiny->new(
		TRIM => 1,
	);

	my $content = '';
	$template->process(
		\$self->skeleton_path->slurp,
		$self->vars,
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

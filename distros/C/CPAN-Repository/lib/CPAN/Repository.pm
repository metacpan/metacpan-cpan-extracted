package CPAN::Repository;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: API to access a directory which can be served as CPAN repository

use Moo;

our $VERSION = '0.010';

use File::Path qw( make_path );
use File::Spec::Functions ':ALL';
use CPAN::Repository::Mailrc;
use CPAN::Repository::Packages;
use CPAN::Repository::Perms;
use File::Copy;

has dir => (
	is => 'ro',
	required => 1,
);

has real_dir => (
	is => 'ro',
	lazy => 1,
	builder => '_build_real_dir',
);

sub _build_real_dir { catdir(splitdir(shift->dir)) }

sub splitted_dir { splitdir(shift->real_dir) }

has url => (
	is => 'ro',
	lazy => 1,
	builder => '_build_url',
);

sub _build_url { 'http://cpan.perl.org/' }

has written_by => (
	is => 'ro',
	lazy => 1,
	builder => '_build_written_by',
);

sub _build_written_by { (ref shift).' '.$VERSION }

has mailrc => (
	is => 'ro',
	lazy => 1,
	builder => '_build_mailrc',
	handles => [qw(
		get_alias
	)],
);

sub _build_mailrc {
	my ( $self ) = @_;
	return CPAN::Repository::Mailrc->new({
		repository_root => $self->real_dir,
	});
}

has perms => (
	is => 'ro',
	lazy => 1,
	builder => '_build_perms',
	handles => [qw(
		get_perms
		get_perms_by_userid
	)],
);

sub _build_perms {
	my ( $self ) = @_;
	return CPAN::Repository::Perms->new({
		repository_root => $self->real_dir,
		written_by => $self->written_by,
	});
}


has packages => (
	is => 'ro',
	lazy => 1,
	builder => '_build_packages',
	handles => [qw(
		get_module
		get_module_version
	)],
);

sub _build_packages {
	my ( $self ) = @_;
	return CPAN::Repository::Packages->new({
		repository_root => $self->real_dir,
		url => $self->url,
		written_by => $self->written_by,
		authorbase_path_parts => [$self->authorbase_path_parts],
	});
}

sub is_initialized {
	my ( $self ) = @_;
	$self->mailrc->exist && $self->packages->exist;
}

sub initialize {
	my ( $self ) = @_;
	die "there exist already a repository at ".$self->real_dir if $self->is_initialized;
	$self->mailrc->save;
	$self->packages->save;
	$self->perms->save;
}

sub add_author_distribution {
	my ( $self, $author, $distribution_filename, $path ) = @_;
	my @fileparts = splitdir( $distribution_filename );
	my $filename = pop(@fileparts);
	my $author_path_filename;
	my $target_dir = $self->mkauthordir($author);
	if ($path) {
		my $path_dir = catfile( $self->splitted_dir, $self->authorbase_path_parts, $path );
		$self->mkdir( $path_dir ) unless -d $path_dir;
		$author_path_filename = catfile( $path, $filename );
	} else {
		$author_path_filename = catfile( $self->author_path_parts($author), $filename );
	}
	copy($distribution_filename,catfile( $self->splitted_dir, $self->authorbase_path_parts, $author_path_filename ));
	$self->packages->add_distribution($author_path_filename)->save;
	$self->mailrc->set_alias($author)->save unless defined $self->mailrc->aliases->{$author};
	return catfile( $self->authorbase_path_parts, $self->author_path_parts($author), $filename );
}

sub set_perms {
	my $self = shift;
	$self->perms->set_perms(@_)->save;
}

sub set_alias {
	my ( $self, $author, $alias ) = @_;
	$self->mailrc->set_alias($author,$alias)->save;
}

sub mkauthordir {
	my ( $self, $author ) = @_;
	my $authordir = $self->authordir($author);
	$self->mkdir( $authordir ) unless -d $authordir;
	return $authordir;
}

sub author_path_parts {
	my ( $self, $author ) = @_;
	return substr( $author, 0, 1 ), substr( $author, 0, 2 ), $author;
}

sub authorbase_path_parts { 'authors', 'id' }

sub authordir {
	my ( $self, $author ) = @_;
	return catdir( $self->splitted_dir, $self->authorbase_path_parts, $self->author_path_parts($author) );
}

sub modules {
	my ( $self ) = @_;
	my %modules;
	for (keys %{$self->packages->modules}) {
		$modules{$_} = catfile( $self->splitted_dir, $self->authorbase_path_parts, splitdir( $self->packages->modules->{$_}->[1] ) );
	}
	return \%modules;
}

sub timestamp { shift->packages->timestamp }

#
# Utilities
#

sub mkdir {
	my ( $self, @path ) = @_;
	make_path(catdir(@path),{ error => \my $err });
	if (@$err) {
		for my $diag (@$err) {
			my ($file, $message) = %$diag;
			if ($file eq '') {
				die "general error: $message\n";
			} else {
				die "problem making path $file: $message\n";
			}
		}
	}
}

1;

__END__

=pod

=head1 NAME

CPAN::Repository - API to access a directory which can be served as CPAN repository

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use CPAN::Repository;

  my $repo = CPAN::Repository->new({
    dir => '/var/www/greypan.company.org/htdocs/',
    url => 'http://greypan.company.org/',
  });
  
  $repo->initialize unless $repo->is_initialized;
  
  $repo->add_author_distribution('AUTHOR','My-Distribution-0.001.tar.gz');
  $repo->add_author_distribution('AUTHOR2','Other-Dist-0.001.tar.gz','Custom/Own/Path');
  $repo->set_alias('AUTHOR','The author <author@company.org>');
  $repo->set_alias('AUTHOR2','The other author <author@company.org>');
  
  my %modules = %{$repo->modules};
  
  my $fullpath_to_authordir = $repo->authordir('SOMEONE');
 
  my $packages = $repo->packages; # gives back a CPAN::Repository::Packages
  my $mailrc = $repo->mailrc; # gives back a CPAN::Repository::Mailrc

=head1 DESCRIPTION

This module is made for representing a directory which can be used as own CPAN for modules, so it can be a GreyPAN, a DarkPAN or even can be
used to manage a mirror of real CPAN your own way. Some code parts are taken from CPAN::Dark of B<CHROMATIC> and L<CPAN::Mini::Inject> of B<MITHALDU>.

=encoding utf8

=head1 SEE ALSO

L<CPAN::Repository::Packages>

L<CPAN::Repository::Mailrc>

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-cpan-repository
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-cpan-repository/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by DuckDuckGo, Inc. L<http://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

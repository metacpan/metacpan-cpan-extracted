package CPAN::Repository::Role::File;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for file functions

use Moo::Role;

our $VERSION = '0.010';

use File::Path qw( make_path );
use File::Spec::Functions ':ALL';
use IO::Zlib;
use IO::File;

requires qw( file_parts generate_content );

has repository_root => (
	is => 'ro',
	required => 1,
);

has generate_uncompressed => (
	is => 'ro',
	lazy => 1,
	builder => '_build_generate_uncompressed',
);

sub _build_generate_uncompressed { 1 }

sub path_inside_root {
	my ( $self ) = @_;
	return join("/",$self->file_parts);
}

sub compressed_path_inside_root {
	my ( $self ) = @_;
	return join("/",$self->file_parts).".gz";
}

sub full_filename {
	my ( $self ) = @_;
	return catfile( splitdir($self->repository_root), $self->file_parts );
}

sub full_compressed_filename { shift->full_filename.".gz" }

sub exist {
	my ( $self ) = @_;
	return 0 unless -f $self->full_compressed_filename;
	return 1;
}

sub save {
	my ( $self ) = @_;
	my @pps = $self->file_parts;
	pop(@pps);
	$self->mkdir( splitdir( $self->repository_root ), @pps ) unless -d catdir( $self->repository_root, @pps );
	my $content = $self->generate_content;
	my $gz = IO::Zlib->new($self->full_compressed_filename, "w") or die "cant write to ".$self->full_compressed_filename;
	print $gz $content;
	$gz->close;
	if ($self->generate_uncompressed) {
		my $txt = IO::File->new($self->full_filename, "w") or die "cant write to ".$self->full_filename;
		print $txt $content;
		$txt->close;
	}
	return 1;
}

sub get_file_lines {
	my ( $self ) = @_;
	my $gz = IO::Zlib->new($self->full_compressed_filename, "r") or die "cant read ".$self->full_compressed_filename;
	return <$gz>;
}

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

CPAN::Repository::Role::File - Role for file functions

=head1 VERSION

version 0.010

=encoding utf8

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

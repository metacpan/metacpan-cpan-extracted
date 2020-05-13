package Beam::Make::Cache;
our $VERSION = '0.001';
# ABSTRACT: Store information about recipes performed

#pod =head1 SYNOPSIS
#pod
#pod     my $cache = Beam::Make::Cache->new;
#pod
#pod     # Update the cache and track what the content should be
#pod     $cache->set( 'recipe', 'content hash' );
#pod
#pod     # Set the last modified time to a specific time by passing
#pod     # a Time::Piece object
#pod     $cache->set( 'recipe', 'content hash', $timestamp );
#pod
#pod     # Get a Time::Piece object if the content hashes match
#pod     # Otherwise returns 0
#pod     my $time = $cache->last_modified( 'recipe', 'content hash' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class provides an API to access timestamps and content hashes to validate
#pod recipes and determine which recipes are out-of-date and should be re-run.
#pod
#pod =head2 Limitations
#pod
#pod The cache file cannot be accessed by more than one process. This limitation may
#pod be fixed in the future. Other cache modules that use distributed databases may
#pod also be created in the future.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>
#pod
#pod =cut

use v5.20;
use warnings;
use Moo;
use experimental qw( signatures postderef );
use File::stat;
use Time::Piece;
use Scalar::Util qw( blessed );
use YAML ();

#pod =attr file
#pod
#pod The path to a file to use for the cache. Defaults to C<.Beamfile.cache> in
#pod the current directory.
#pod
#pod =cut

has file => ( is => 'ro', default => sub { '.Beamfile.cache' } );
has _last_read => ( is => 'rw', default => 0 );
has _cache => ( is => 'rw', default => sub { {} } );

#pod =method set
#pod
#pod     $cache->set( $name, $hash, $time );
#pod
#pod     # Update modified time to now
#pod     $cache->set( $name, $hash );
#pod
#pod Set an entry in the cache. C<$name> is the recipe name. C<$hash> is an identifier
#pod for the content (usually a base64 SHA-1 hash from L<Digest::SHA>). C<$time> is a
#pod L<Time::Piece> object to save as the last modified time. If C<$time> is not provided,
#pod defaults to now.
#pod
#pod =cut

sub set( $self, $name, $hash, $time=Time::Piece->new ) {
    my $cache = $self->_fetch_cache;
    $cache->{ $name } = {
        hash => $hash,
        time => blessed $time eq 'Time::Piece' ? $time->epoch : $time,
    };
    $self->_write_cache( $cache );
}

#pod =method last_modified
#pod
#pod     my $time = $cache->last_modified( $name, $hash );
#pod
#pod Get the last modified timestamp (as a L<Time::Piece> object) for the
#pod given recipe C<$name>. If the C<$hash> does not match what was given to
#pod L</set>, or if the recipe has never been made, returns C<0>.
#pod
#pod =cut

sub last_modified( $self, $name, $hash ) {
    my $cache = $self->_fetch_cache;
    return Time::Piece->new( $cache->{ $name }{ time } )
        if $cache->{ $name }
        && $cache->{ $name }{ hash } eq $hash
        ;
    return 0;
}

sub _fetch_cache( $self ) {
    my $last_read = $self->_last_read;
    if ( -e $self->file && ( !$last_read || stat( $self->file )->mtime > $last_read ) ) {
        $self->_last_read( stat( $self->file )->mtime );
        $self->_cache( YAML::LoadFile( $self->file ) );
    }
    return $self->_cache;
}

sub _write_cache( $self, $cache ) {
    my $old_cache = $self->_fetch_cache;
    $cache = { %$old_cache, %$cache };
    YAML::DumpFile( $self->file, $cache );
    $self->_cache( $cache );
    $self->_last_read( stat( $self->file )->mtime );
    return;
}

1;

__END__

=pod

=head1 NAME

Beam::Make::Cache - Store information about recipes performed

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cache = Beam::Make::Cache->new;

    # Update the cache and track what the content should be
    $cache->set( 'recipe', 'content hash' );

    # Set the last modified time to a specific time by passing
    # a Time::Piece object
    $cache->set( 'recipe', 'content hash', $timestamp );

    # Get a Time::Piece object if the content hashes match
    # Otherwise returns 0
    my $time = $cache->last_modified( 'recipe', 'content hash' );

=head1 DESCRIPTION

This class provides an API to access timestamps and content hashes to validate
recipes and determine which recipes are out-of-date and should be re-run.

=head2 Limitations

The cache file cannot be accessed by more than one process. This limitation may
be fixed in the future. Other cache modules that use distributed databases may
also be created in the future.

=head1 ATTRIBUTES

=head2 file

The path to a file to use for the cache. Defaults to C<.Beamfile.cache> in
the current directory.

=head1 METHODS

=head2 set

    $cache->set( $name, $hash, $time );

    # Update modified time to now
    $cache->set( $name, $hash );

Set an entry in the cache. C<$name> is the recipe name. C<$hash> is an identifier
for the content (usually a base64 SHA-1 hash from L<Digest::SHA>). C<$time> is a
L<Time::Piece> object to save as the last modified time. If C<$time> is not provided,
defaults to now.

=head2 last_modified

    my $time = $cache->last_modified( $name, $hash );

Get the last modified timestamp (as a L<Time::Piece> object) for the
given recipe C<$name>. If the C<$hash> does not match what was given to
L</set>, or if the recipe has never been made, returns C<0>.

=head1 SEE ALSO

L<Beam::Make>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

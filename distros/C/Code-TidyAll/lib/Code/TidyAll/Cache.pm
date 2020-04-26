package Code::TidyAll::Cache;

use strict;
use warnings;

use Digest::SHA qw(sha1_hex);
use Path::Tiny qw(path);
use Specio::Library::Path::Tiny;

use Moo;

our $VERSION = '0.78';

has cache_dir => (
    is       => 'ro',
    isa      => t('Path'),
    required => 1,
);

sub get {
    my ( $self, $key ) = @_;

    my $file = $self->_path_for_key($key);
    if ( $file->exists ) {
        return $file->slurp_raw;
    }
    else {
        return undef;
    }
}

sub set {
    my ( $self, $key, $value ) = @_;

    my $file = $self->_path_for_key($key);
    $file->parent->mkpath( { mode => 0755 } );
    $file->spew_raw($value);

    return;
}

sub remove {
    my ( $self, $key, $value ) = @_;

    $self->_path_for_key($key)->remove;

    return;
}

sub _path_for_key {
    my ( $self, $key ) = @_;

    my $sig = sha1_hex($key);
    return $self->cache_dir->child( substr( $sig, 0, 1 ), "$sig.dat" );
}

1;

# ABSTRACT: A simple caching engine which stores key/value pairs

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Cache - A simple caching engine which stores key/value pairs

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut

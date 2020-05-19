package Beam::Make::Docker::Image;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe to build/pull/update a Docker image

#pod =head1 SYNOPSIS
#pod
#pod     ### Beamfile
#pod     nordaaker/convos:
#pod         $class: Beam::Make::Docker::Image
#pod         image: nordaaker/convos
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class updates a Docker image, either by building it
#pod or by checking a remote repository.
#pod
#pod B<NOTE:> This works for basic use-cases, but could use some
#pod improvements. Improvements should attempt to match the C<docker-compose>
#pod file syntax when possible.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make::Docker::Container>, L<Beam::Make>, L<https://docker.com>
#pod
#pod =cut

use v5.20;
use warnings;
use autodie qw( :all );
use Moo;
use Time::Piece;
use Log::Any qw( $LOG );
use File::Which qw( which );
use JSON::PP qw( decode_json );
use Digest::SHA qw( sha1_base64 );
use experimental qw( signatures postderef );

extends 'Beam::Make::Recipe';

#pod =attr image
#pod
#pod The image to build or pull. If building, will tag the resulting image.
#pod Required.
#pod
#pod =cut

has image => (
    is => 'ro',
    required => 1,
);

#pod =attr build
#pod
#pod The path to the build context. If set, will build an image instead of pulling
#pod from a repository.
#pod
#pod =cut

has build => (
    is => 'ro',
);

#pod =attr args
#pod
#pod A mapping of build args (C<< --build-arg <KEY>=<VALUE> >>).
#pod
#pod =cut

has args => (
    is => 'ro',
    default => sub { {} },
);

#pod =attr tags
#pod
#pod A list of additional tags for the image.
#pod
#pod =cut

has tags => (
    is => 'ro',
    default => sub { [] },
);

#pod =attr dockerfile
#pod
#pod The name of the Dockerfile to use. If unset, Docker uses the default name: C<Dockerfile>.
#pod
#pod =cut

has dockerfile => (
    is => 'ro',
);

#pod =attr docker
#pod
#pod The path to the Docker executable to use. Defaults to looking up
#pod C<docker> in C<PATH>.
#pod
#pod =cut

has docker => (
    is => 'ro',
    default => sub { which 'docker' },
);

sub make( $self, %vars ) {
    my @cmd = ( $self->docker );
    if ( my $context = $self->build ) {
        push @cmd, 'build', '-t', $self->image;
        if ( my @tags = $self->tags->@* ) {
            push @cmd, map {; '-t', $_ } @tags;
        }
        if ( my %args = $self->args->%* ) {
            push @cmd, map {; '--build-arg', join '=', $_, $args{$_} } keys %args;
        }
        if ( my $file = $self->dockerfile ) {
            push @cmd, '-f', $file;
        }
        push @cmd, $context;
    }
    else {
        push @cmd, 'pull', $self->image;
    }
    @cmd = $self->fill_env( @cmd );
    $LOG->debug( 'Running docker command: ', @cmd );
    system @cmd;
    delete $self->{_inspect_output} if exists $self->{_inspect_output};

    # Update the cache
    my $info = $self->_image_info;
    my $created = $info->{Created} =~ s/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*$/$1/r;
    my $iso8601 = '%Y-%m-%dT%H:%M:%S';
    $self->cache->set( $self->name, $self->_cache_hash, Time::Piece->strptime( $created, $iso8601 ) );

    return 0;
}

sub _image_info( $self ) {
    state $json = JSON::PP->new->canonical->utf8;
    my $output = $self->{_inspect_output};
    if ( !$output ) {
        my $cmd = join ' ', $self->docker, qw( image inspect ), $self->image;
        $LOG->debug( 'Running docker command:', $cmd );
        $output = `$cmd`;
        $self->{_inspect_output} = $output;
    }
    my ( $image ) = $json->decode( $output )->@*;
    return $image || {};
}

sub _config_hash( $self ) {
    my @keys = grep !/^_|^name$|^cache$/, keys %$self;
    my $json = JSON::PP->new->canonical->utf8;
    my $hash = sha1_base64( $json->encode( { $self->%{ @keys } } ) );
    return $hash;
}

sub _cache_hash( $self ) {
    my $image = $self->_image_info;
    return '' unless keys %$image;
    return sha1_base64( $image->{Id} . $self->_config_hash );
}

sub last_modified( $self ) {
    return $self->cache->last_modified( $self->name, $self->_cache_hash );
}

1;

__END__

=pod

=head1 NAME

Beam::Make::Docker::Image - A Beam::Make recipe to build/pull/update a Docker image

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### Beamfile
    nordaaker/convos:
        $class: Beam::Make::Docker::Image
        image: nordaaker/convos

=head1 DESCRIPTION

This L<Beam::Make> recipe class updates a Docker image, either by building it
or by checking a remote repository.

B<NOTE:> This works for basic use-cases, but could use some
improvements. Improvements should attempt to match the C<docker-compose>
file syntax when possible.

=head1 ATTRIBUTES

=head2 image

The image to build or pull. If building, will tag the resulting image.
Required.

=head2 build

The path to the build context. If set, will build an image instead of pulling
from a repository.

=head2 args

A mapping of build args (C<< --build-arg <KEY>=<VALUE> >>).

=head2 tags

A list of additional tags for the image.

=head2 dockerfile

The name of the Dockerfile to use. If unset, Docker uses the default name: C<Dockerfile>.

=head2 docker

The path to the Docker executable to use. Defaults to looking up
C<docker> in C<PATH>.

=head1 SEE ALSO

L<Beam::Make::Docker::Container>, L<Beam::Make>, L<https://docker.com>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

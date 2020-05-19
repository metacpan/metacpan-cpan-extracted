package Beam::Make::Docker::Container;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe to build a Docker container

#pod =head1 SYNOPSIS
#pod
#pod     ### Beamfile
#pod     convos:
#pod         $class: Beam::Make::Docker::Container
#pod         image: nordaaker/convos:latest
#pod         restart: unless-stopped
#pod         ports:
#pod             - 8080:3000
#pod         volumes:
#pod             - $HOME/convos/data:/data
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class creates a Docker container, re-creating
#pod it if the underlying image has changed.
#pod
#pod B<NOTE:> This works for basic use-cases, but could use some
#pod improvements. Improvements should attempt to match the C<docker-compose>
#pod file syntax when possible.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make::Docker::Image>, L<Beam::Make>, L<https://docker.com>
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
#pod The image to use for this container. Required.
#pod
#pod =cut

has image => (
    is => 'ro',
    required => 1,
);

#pod =attr command
#pod
#pod The command to run, overriding the image's default command. Can be a list or a string.
#pod
#pod =cut

has command => (
    is => 'ro',
);

#pod =attr volumes
#pod
#pod A list of volumes to map. Volumes are strings with the local volume or
#pod Docker named volume and the destination mount point separated by a C<:>.
#pod
#pod =cut

has volumes => (
    is => 'ro',
);

#pod =attr ports
#pod
#pod A list of ports to map. Ports are strings with the local port and the
#pod destination port separated by a C<:>.
#pod
#pod =cut

has ports => (
    is => 'ro',
);

#pod =attr environment
#pod
#pod The environment variables to set in this container. A list of C<< NAME=VALUE >> strings.
#pod
#pod =cut

has environment => (
    is => 'ro',
);

#pod =attr restart
#pod
#pod The restart policy for this container. One of C<no>, C<on-failure>,
#pod C<always>, C<unless-stopped>.
#pod
#pod =cut

has restart => (
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
    # Always clean if we're making: Docker can only have one container
    # with a given name.
    $self->clean;

    my @cmd = (
        $self->docker, qw( container create ),
        '--name' => $self->name,
        ( $self->restart ? ( '--restart' => $self->restart ) : () ),
        ( $self->environment ? map {; "-e", $_ } $self->environment->@* : () ),
        ( $self->ports ? map {; "-p", $_ } $self->ports->@* : () ),
        ( $self->volumes ? map {; "-v", $_ } $self->volumes->@* : () ),
        $self->image,
    );
    if ( my $cmd = $self->command ) {
        push @cmd, ref $cmd eq 'ARRAY' ? @$cmd : $cmd;
    }
    @cmd = $self->fill_env( @cmd );
    $LOG->debug( 'Running docker command:', @cmd );
    system @cmd;
    delete $self->{_inspect_output} if exists $self->{_inspect_output};

    # Update the cache
    my $info = $self->_container_info;
    my $created = $info->{Created} =~ s/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*$/$1/r;
    my $iso8601 = '%Y-%m-%dT%H:%M:%S';
    $self->cache->set( $self->name, $self->_cache_hash, Time::Piece->strptime( $created, $iso8601 ) );

    $self->start;
    return 0;
}

sub clean( $self ) {
    my $info = $self->_container_info;
    if ( keys %$info ) {
        if ( $info->{State}{Running} ) {
            system qw( docker stop ), $self->name;
        }
        system qw( docker rm ), $self->name;
    }
}

sub start( $self ) {
    system qw( docker start ), $self->name;
}

sub _container_info( $self ) {
    state $json = JSON::PP->new->canonical->utf8;
    my $output = $self->{_inspect_output};
    if ( !$output ) {
        my $cmd = join ' ', $self->docker, qw( container inspect ), $self->name;
        $LOG->debug( 'Running docker command:', $cmd );
        $output = `$cmd`;
        $self->{_inspect_output} = $output;
    }
    my ( $container ) = $json->decode( $output )->@*;
    return $container || {};
}

sub _config_hash( $self ) {
    my @keys = grep !/^_|^name$|^cache$/, keys %$self;
    my $json = JSON::PP->new->canonical->utf8;
    my $hash = sha1_base64( $json->encode( { $self->%{ @keys } } ) );
    return $hash;
}

sub _cache_hash( $self ) {
    my $container = $self->_container_info;
    return '' unless keys %$container;
    return sha1_base64( $container->{Id} . $self->_config_hash );
}

sub last_modified( $self ) {
    return $self->cache->last_modified( $self->name, $self->_cache_hash );
}

1;

__END__

=pod

=head1 NAME

Beam::Make::Docker::Container - A Beam::Make recipe to build a Docker container

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### Beamfile
    convos:
        $class: Beam::Make::Docker::Container
        image: nordaaker/convos:latest
        restart: unless-stopped
        ports:
            - 8080:3000
        volumes:
            - $HOME/convos/data:/data

=head1 DESCRIPTION

This L<Beam::Make> recipe class creates a Docker container, re-creating
it if the underlying image has changed.

B<NOTE:> This works for basic use-cases, but could use some
improvements. Improvements should attempt to match the C<docker-compose>
file syntax when possible.

=head1 ATTRIBUTES

=head2 image

The image to use for this container. Required.

=head2 command

The command to run, overriding the image's default command. Can be a list or a string.

=head2 volumes

A list of volumes to map. Volumes are strings with the local volume or
Docker named volume and the destination mount point separated by a C<:>.

=head2 ports

A list of ports to map. Ports are strings with the local port and the
destination port separated by a C<:>.

=head2 environment

The environment variables to set in this container. A list of C<< NAME=VALUE >> strings.

=head2 restart

The restart policy for this container. One of C<no>, C<on-failure>,
C<always>, C<unless-stopped>.

=head2 docker

The path to the Docker executable to use. Defaults to looking up
C<docker> in C<PATH>.

=head1 SEE ALSO

L<Beam::Make::Docker::Image>, L<Beam::Make>, L<https://docker.com>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

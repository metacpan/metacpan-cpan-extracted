package API::Docker;
# ABSTRACT: Perl client for the Docker Engine API
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

use API::Docker::API::System;
use API::Docker::API::Containers;
use API::Docker::API::Images;
use API::Docker::API::Networks;
use API::Docker::API::Volumes;
use API::Docker::API::Exec;


has host => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_HOST} // 'unix:///var/run/docker.sock' },
);


has api_version => (
  is      => 'rwp',
  default => undef,
);


has tls => (
  is      => 'ro',
  default => 0,
);


has cert_path => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_CERT_PATH} },
);


has _version_negotiated => (
  is      => 'rw',
  default => 0,
);

with 'API::Docker::Role::HTTP';

has system => (
  is      => 'lazy',
  builder => sub { API::Docker::API::System->new(client => $_[0]) },
);


has containers => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Containers->new(client => $_[0]) },
);


has images => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Images->new(client => $_[0]) },
);


has networks => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Networks->new(client => $_[0]) },
);


has volumes => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Volumes->new(client => $_[0]) },
);


has exec => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Exec->new(client => $_[0]) },
);


sub negotiate_version {
  my ($self) = @_;
  return if $self->_version_negotiated;
  return if defined $self->api_version;

  $log->debug("Auto-negotiating API version");
  my $version_info = $self->_request('GET', '/version');
  if ($version_info && $version_info->{ApiVersion}) {
    $self->_set_api_version($version_info->{ApiVersion});
    $log->debugf("Negotiated API version: %s", $version_info->{ApiVersion});
  }
  $self->_version_negotiated(1);
}


around _request => sub {
  my ($orig, $self, $method, $path, %opts) = @_;

  # Auto-negotiate before any versioned request, but not for /version itself
  if ($path ne '/version' && !defined $self->api_version && !$self->_version_negotiated) {
    $self->negotiate_version;
  }

  return $self->$orig($method, $path, %opts);
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker - Perl client for the Docker Engine API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use API::Docker;

    # Connect to local Docker daemon via Unix socket
    my $docker = API::Docker->new;

    # Or connect to remote Docker daemon
    my $docker = API::Docker->new(
        host => 'tcp://192.168.1.100:2375',
    );

    # System information
    my $info = $docker->system->info;
    my $version = $docker->system->version;

    # Container management
    my $containers = $docker->containers->list(all => 1);
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
    );
    $docker->containers->start($result->{Id});

    # Image operations
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    my $images = $docker->images->list;

    # Network and volume management
    my $networks = $docker->networks->list;
    my $volumes = $docker->volumes->list;

=head1 DESCRIPTION

API::Docker is a Perl client for the Docker Engine API. It provides a clean
object-oriented interface to manage Docker containers, images, networks, and
volumes.

Key features:

=over

=item * Pure Perl implementation with minimal dependencies

=item * Unix socket and TCP transport support

=item * Automatic API version negotiation

=item * Object-oriented entity classes (Container, Image, Network, Volume)

=item * Comprehensive logging via L<Log::Any>

=back

=head2 Architecture

The distribution is organized into several layers:

=over

=item * B<Main Client> - L<API::Docker> - Entry point with API version negotiation

=item * B<API Modules> - Resource-specific API methods:

=over

=item * L<API::Docker::API::System> - System info, version, ping

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Exec into containers

=back

=item * B<Entity Classes> - Object wrappers for Docker resources:

=over

=item * L<API::Docker::Container> - Container entity with convenience methods

=item * L<API::Docker::Image> - Image entity

=item * L<API::Docker::Network> - Network entity

=item * L<API::Docker::Volume> - Volume entity

=back

=item * B<HTTP Role> - L<API::Docker::Role::HTTP> - HTTP transport layer

=back

=head2 host

Docker daemon connection URL. Defaults to C<$ENV{DOCKER_HOST}> or
C<unix:///var/run/docker.sock>.

Supported formats:

=over

=item * C<unix:///path/to/socket> - Unix socket (default)

=item * C<tcp://host:port> - TCP connection

=back

=head2 api_version

Docker API version to use (e.g., C<1.41>). If not set, the client will
automatically negotiate the highest API version supported by the daemon.

This attribute is set automatically by L</negotiate_version>.

=head2 tls

Enable TLS for secure connections. Defaults to C<0>. Currently experimental.

=head2 cert_path

Path to TLS certificates. Defaults to C<$ENV{DOCKER_CERT_PATH}>.

=head2 system

Returns L<API::Docker::API::System> instance for system operations like
C<info>, C<version>, C<ping>, and C<events>.

=head2 containers

Returns L<API::Docker::API::Containers> instance for container operations like
C<list>, C<create>, C<start>, C<stop>, and C<remove>.

=head2 images

Returns L<API::Docker::API::Images> instance for image operations like
C<list>, C<pull>, C<push>, and C<remove>.

=head2 networks

Returns L<API::Docker::API::Networks> instance for network operations like
C<list>, C<create>, C<connect>, and C<disconnect>.

=head2 volumes

Returns L<API::Docker::API::Volumes> instance for volume operations like
C<list>, C<create>, and C<remove>.

=head2 exec

Returns L<API::Docker::API::Exec> instance for executing commands in containers.

=head2 negotiate_version

    $docker->negotiate_version;

Automatically negotiate the highest API version supported by the Docker daemon.
This is called automatically before the first API request if L</api_version>
is not set.

After negotiation, L</api_version> will contain the negotiated version
(e.g., C<1.41>).

=head1 ENVIRONMENT VARIABLES

=over

=item C<DOCKER_HOST>

Docker daemon connection URL. Used as default for L</host> if not explicitly set.

Examples: C<unix:///var/run/docker.sock>, C<tcp://localhost:2375>

=item C<DOCKER_CERT_PATH>

Path to TLS certificates directory. Used as default for L</cert_path>.

=back

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::HTTP> - HTTP transport implementation

=item * L<API::Docker::API::System> - System and daemon operations

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Execute commands in containers

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

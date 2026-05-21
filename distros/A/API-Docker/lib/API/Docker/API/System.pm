package API::Docker::API::System;
# ABSTRACT: Docker Engine System API
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


sub info {
  my ($self) = @_;
  return $self->client->get('/info');
}


sub version {
  my ($self) = @_;
  return $self->client->get('/version');
}


sub ping {
  my ($self) = @_;
  return $self->client->get('/_ping');
}


sub events {
  my ($self, %opts) = @_;
  my %params;
  $params{since}   = $opts{since}   if defined $opts{since};
  $params{until}   = $opts{until}   if defined $opts{until};
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->get('/events', params => \%params);
}


sub df {
  my ($self) = @_;
  return $self->client->get('/system/df');
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::System - Docker Engine System API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # System information
    my $info = $docker->system->info;
    say "Docker version: " . $info->{ServerVersion};

    # API version
    my $version = $docker->system->version;
    say "API version: " . $version->{ApiVersion};

    # Health check
    my $pong = $docker->system->ping;

    # Monitor events
    my $events = $docker->system->events(
        since => time() - 3600,
    );

    # Disk usage
    my $df = $docker->system->df;

=head1 DESCRIPTION

This module provides access to Docker system-level operations including daemon
information, version detection, health checks, and event monitoring.

Accessed via C<< $docker->system >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 info

    my $info = $system->info;

Get system-wide information about the Docker daemon.

Returns hashref with keys including:

=over

=item * C<ServerVersion> - Docker version

=item * C<Containers> - Total number of containers

=item * C<Images> - Total number of images

=item * C<Driver> - Storage driver

=item * C<MemTotal> - Total memory

=back

=head2 version

    my $version = $system->version;

Get version information about the Docker daemon and API.

Returns hashref with keys including C<ApiVersion>, C<Version>, C<GitCommit>,
C<GoVersion>, C<Os>, and C<Arch>.

=head2 ping

    my $pong = $system->ping;

Health check endpoint. Returns C<OK> string if daemon is responsive.

=head2 events

    my $events = $system->events(
        since   => 1234567890,
        until   => 1234567900,
        filters => { type => ['container'] },
    );

Get real-time events from the Docker daemon.

Options:

=over

=item * C<since> - Show events created since this timestamp

=item * C<until> - Show events created before this timestamp

=item * C<filters> - Hashref of filters (e.g., C<< { type => ['container', 'image'] } >>)

=back

=head2 df

    my $usage = $system->df;

Get data usage information (disk usage by images, containers, and volumes).

Returns hashref with C<LayersSize>, C<Images>, C<Containers>, and C<Volumes> arrays.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

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

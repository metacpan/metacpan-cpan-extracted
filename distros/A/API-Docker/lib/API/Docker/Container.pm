package API::Docker::Container;
# ABSTRACT: Docker container entity
our $VERSION = '0.002';
use Moo;
use namespace::clean;


has client => (
  is       => 'ro',
  weak_ref => 1,
);


has Id            => (is => 'ro');


has Names         => (is => 'ro');


has Image         => (is => 'ro');


has ImageID       => (is => 'ro');
has Command       => (is => 'ro');
has Created       => (is => 'ro');


has State         => (is => 'ro');


has Status        => (is => 'ro');


has Ports         => (is => 'ro');
has Labels        => (is => 'ro');
has SizeRw        => (is => 'ro');
has SizeRootFs    => (is => 'ro');
has HostConfig    => (is => 'ro');
has NetworkSettings => (is => 'ro');
has Mounts        => (is => 'ro');

has Name          => (is => 'ro');


has RestartCount  => (is => 'ro');
has Driver        => (is => 'ro');
has Platform      => (is => 'ro');
has Path          => (is => 'ro');
has Args          => (is => 'ro');
has Config        => (is => 'ro');

sub start {
  my ($self) = @_;
  return $self->client->containers->start($self->Id);
}


sub stop {
  my ($self, %opts) = @_;
  return $self->client->containers->stop($self->Id, %opts);
}


sub restart {
  my ($self, %opts) = @_;
  return $self->client->containers->restart($self->Id, %opts);
}


sub kill {
  my ($self, %opts) = @_;
  return $self->client->containers->kill($self->Id, %opts);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->containers->remove($self->Id, %opts);
}


sub logs {
  my ($self, %opts) = @_;
  return $self->client->containers->logs($self->Id, %opts);
}


sub inspect {
  my ($self) = @_;
  return $self->client->containers->inspect($self->Id);
}


sub pause {
  my ($self) = @_;
  return $self->client->containers->pause($self->Id);
}


sub unpause {
  my ($self) = @_;
  return $self->client->containers->unpause($self->Id);
}


sub top {
  my ($self, %opts) = @_;
  return $self->client->containers->top($self->Id, %opts);
}


sub stats {
  my ($self, %opts) = @_;
  return $self->client->containers->stats($self->Id, %opts);
}


sub is_running {
  my ($self) = @_;
  my $state = $self->State;
  return 0 unless defined $state;
  if (ref $state eq 'HASH') {
    return $state->{Running} ? 1 : 0;
  }
  return lc($state) eq 'running' ? 1 : 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Container - Docker container entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Get container from list or inspect
    my $containers = $docker->containers->list;
    my $container = $containers->[0];

    # Access container properties
    say $container->Id;
    say $container->Status;
    say $container->Image;

    # Perform operations
    $container->start;
    $container->stop(timeout => 10);
    my $logs = $container->logs(tail => 100);
    $container->remove(force => 1);

    # Check state
    if ($container->is_running) {
        say "Container is running";
    }

=head1 DESCRIPTION

This class represents a Docker container and provides convenient access to
container properties and operations. Instances are returned by
L<API::Docker::API::Containers> methods like C<list> and C<inspect>.

Each attribute corresponds to fields in the Docker API container representation.
Methods delegate to L<API::Docker::API::Containers> for operations.

=head2 client

Reference to L<API::Docker> client. Used for delegating operations.

=head2 Id

Container ID (64-character hex string).

=head2 Names

ArrayRef of container names (from C<list>).

=head2 Image

Image name used to create the container.

=head2 Created

Container creation timestamp (Unix epoch).

=head2 State

Container state. From C<list>: string like C<running>, C<exited>. From
C<inspect>: hashref with C<Running>, C<Paused>, C<ExitCode>, etc.

=head2 Status

Human-readable status string (e.g., "Up 2 hours").

=head2 Name

Container name (from C<inspect>, includes leading C</>).

=head2 start

    $container->start;

Start the container. Delegates to L<API::Docker::API::Containers/start>.

=head2 stop

    $container->stop(timeout => 10);

Stop the container. Delegates to L<API::Docker::API::Containers/stop>.

=head2 restart

    $container->restart;

Restart the container.

=head2 kill

    $container->kill(signal => 'SIGTERM');

Send a signal to the container.

=head2 remove

    $container->remove(force => 1);

Remove the container.

=head2 logs

    my $logs = $container->logs(tail => 100);

Get container logs.

=head2 inspect

    my $updated = $container->inspect;

Get fresh container information.

=head2 pause

    $container->pause;

Pause all processes in the container.

=head2 unpause

    $container->unpause;

Unpause the container.

=head2 top

    my $processes = $container->top;

List running processes in the container.

=head2 stats

    my $stats = $container->stats;

Get resource usage statistics.

=head2 is_running

    if ($container->is_running) { ... }

Returns true if container is running, false otherwise. Works with both C<list>
and C<inspect> response formats.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Containers> - Container API operations

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

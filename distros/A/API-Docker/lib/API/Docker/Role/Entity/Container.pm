package API::Docker::Role::Entity::Container;
# ABSTRACT: Container operations, on the generated container types
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'id';
use API::Docker::Type::ContainerInspectResponse;
use API::Docker::Type::ContainerSummary;
use Carp qw( croak );
use Package::Stash;
use Scalar::Util qw( blessed );
use namespace::clean;


sub start {
  my ($self) = @_;
  return $self->client->containers->start($self->id);
}


sub stop {
  my ($self, %opts) = @_;
  return $self->client->containers->stop($self->id, %opts);
}


sub restart {
  my ($self, %opts) = @_;
  return $self->client->containers->restart($self->id, %opts);
}


sub kill {
  my ($self, %opts) = @_;
  return $self->client->containers->kill($self->id, %opts);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->containers->remove($self->id, %opts);
}


sub logs {
  my ($self, %opts) = @_;
  return $self->client->containers->logs($self->id, %opts);
}


sub attach {
  my ($self, %opts) = @_;
  return $self->client->containers->attach($self->id, %opts);
}


sub inspect {
  my ($self) = @_;
  return $self->client->containers->inspect($self->id);
}


sub pause {
  my ($self) = @_;
  return $self->client->containers->pause($self->id);
}


sub unpause {
  my ($self) = @_;
  return $self->client->containers->unpause($self->id);
}


sub top {
  my ($self, %opts) = @_;
  return $self->client->containers->top($self->id, %opts);
}


sub stats {
  my ($self, %opts) = @_;
  return $self->client->containers->stats($self->id, %opts);
}


sub changes {
  my ($self) = @_;
  return $self->client->containers->changes($self->id);
}


sub export {
  my ($self) = @_;
  return $self->client->containers->export($self->id);
}


sub resize {
  my ($self, %opts) = @_;
  return $self->client->containers->resize($self->id, %opts);
}


sub get_archive {
  my ($self, %opts) = @_;
  return $self->client->containers->get_archive($self->id, %opts);
}


sub put_archive {
  my ($self, $tar, %opts) = @_;
  return $self->client->containers->put_archive($self->id, $tar, %opts);
}


sub stat_archive {
  my ($self, %opts) = @_;
  return $self->client->containers->stat_archive($self->id, %opts);
}


sub is_running {
  my ($self) = @_;
  my $state = $self->state;
  return 0 unless defined $state;
  # The one place the two shapes have to be told apart: `state` is the status
  # string on a ContainerSummary and an API::Docker::Type::ContainerState on
  # a ContainerInspectResponse.
  return $state->running ? 1 : 0 if blessed $state;
  return lc($state) eq 'running' ? 1 : 0;
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Containers, which is the other
# candidate: loading this role is then what puts the methods on the classes,
# and there is no program in which an API::Docker::Type::ContainerSummary has
# ->start and another in which it does not, depending on which module was
# loaded first.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. None of the 19 names collides today; a future one says so
# on the first `use`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class (
    'API::Docker::Type::ContainerSummary',
    'API::Docker::Type::ContainerInspectResponse',
  ) {
    my $fields = $class->docker_attributes;
    my @clash = sort grep { $fields->{$_} } @provided;
    croak __PACKAGE__ . ': ' . $class . ' declares ' . join(', ', @clash)
      . ' as a daemon field; the generated accessor would win over the '
      . 'method of that name and it would be missing without a word'
      if @clash;
    Moo::Role->apply_roles_to_package($class, __PACKAGE__);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Entity::Container - Container operations, on the generated container types

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # from list: an API::Docker::Type::ContainerSummary
    my ($container) = @{ $docker->containers->list };

    say $container->id;
    say $container->status;             # "Up 2 hours"
    say $container->state;              # "running"

    $container->start;
    $container->stop(timeout => 10);
    my $logs = $container->logs(tail => 100);
    $container->remove(force => 1);

    # from inspect: an API::Docker::Type::ContainerInspectResponse, where
    # the same methods work and `state` is an object
    my $full = $docker->containers->inspect($container->id);
    say $full->state->status;
    say $full->state->exit_code;

    if ($full->is_running) { ... }

=head1 DESCRIPTION

The convenience methods of a container. This role is composed, at load time,
into the two generated classes the daemon answers container requests with:

=over

=item * L<API::Docker::Type::ContainerSummary> -- one entry of
C<GET /containers/json>, what L<API::Docker::API::Containers/list> returns

=item * L<API::Docker::Type::ContainerInspectResponse> -- the body of
C<GET /containers/{id}/json>, what L<API::Docker::API::Containers/inspect>
returns

=back

Every method here forwards to L<API::Docker::API::Containers> with the
container's own C<id> and returns whatever that method returns; the options
are that method's options, undocumented here on purpose so there is one
place to correct when the engine's are found to be something else.

The fields differ between the two classes -- see
L<API::Docker::API::Containers/"The two container shapes"> for the
differences that have bitten. L</is_running> is the one method that reads
both shapes.

Why the methods are a role applied to generated classes rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 start

    $container->start;

    say 'was already running' unless $container->start;

Start the container. Returns 1 when it was started and 0 when it was already
running. Delegates to L<API::Docker::API::Containers/start>, which documents
what that 0 replaces.

=head2 stop

    $container->stop(timeout => 10);

Stop the container. Returns 1 when it was stopped and 0 when it was already
stopped. Delegates to L<API::Docker::API::Containers/stop>.

=head2 restart

    $container->restart;

Restart the container. Returns 1/0 as L<API::Docker::API::Containers/restart>
does; no engine measured here answers a restart with 304, so it is 1.

=head2 kill

    $container->kill(signal => 'SIGTERM');

Send a signal to the container.

=head2 remove

    $container->remove(force => 1);

Remove the container.

=head2 logs

    my $logs = $container->logs(tail => 100);

    # or follow it, one frame at a time
    $container->logs(follow => 1, tail => 0,
        on_frame => sub { print $_[0]{data} });

Get container logs. Every option goes to
L<API::Docker::API::Containers/logs>, C<follow> and C<on_frame> included; with
a callback the return value is that method's summary HashRef rather than the
frames.

=head2 attach

    my $frames = $container->attach;

Attach to the container's output and return the frames, one-way. Every option
goes to L<API::Docker::API::Containers/attach>, C<on_frame> included; with a
callback the return value is that method's summary HashRef rather than the
frames. Without options it replays what the container already wrote and
returns; C<< stream => 1 >> on a container that is not running never
returns -- not even with a callback -- see
L<API::Docker::API::Containers/"The defaults follow the engine">.

B<The container must be running.> Attaching to one that has already exited
destroys its exit status on Podman, so the call checks first and croaks rather
than attaching; L</logs> is how a finished container's output is read.
C<< require_running => 0 >> attaches anyway. The check is a pre-flight one and
does not close the race against a container stopping underneath it -- see
L<API::Docker::API::Containers/"This method refuses a container that is not running">.

=head2 inspect

    my $updated = $container->inspect;

Get fresh container information. Returns an
L<API::Docker::Type::ContainerInspectResponse> whatever the invocant was, so
this is also how a C<list> entry is turned into the full shape.

=head2 pause

    $container->pause;

Pause all processes in the container. Returns 1/0 as
L<API::Docker::API::Containers/pause> does; an already-paused container is an
error there, not a 0.

=head2 unpause

    $container->unpause;

Unpause the container. Returns 1/0 as
L<API::Docker::API::Containers/unpause> does.

=head2 top

    my $processes = $container->top;

List running processes in the container.

=head2 stats

    my $stats = $container->stats;

    # or follow the readings
    $container->stats(stream => 1, on_event => sub { ... });

Get resource usage statistics. Every option goes to
L<API::Docker::API::Containers/stats>, C<stream> and C<on_event> included;
with a callback the return value is that method's summary HashRef rather than
the readings.

=head2 changes

    for my $change (@{ $container->changes }) { ... }

Paths that differ from the image, as C<< { Path => ..., Kind => ... } >>.
Delegates to L<API::Docker::API::Containers/changes>, which documents what the
three C<Kind> numbers mean.

=head2 export

    my $tar = $container->export;

The container's filesystem as raw tar bytes.

=head2 resize

    $container->resize(h => 40, w => 120);

Resize the container's TTY.

=head2 get_archive

    my $tar = $container->get_archive(path => '/etc/hostname');

Read a path out of the container as raw tar bytes.

=head2 put_archive

    $container->put_archive($tar, path => '/opt/app');

Unpack a tar archive into a directory in the container.

=head2 stat_archive

    my $stat = $container->stat_archive(path => '/etc/hostname');

Stat a path in the container without transferring it.

=head2 is_running

    if ($container->is_running) { ... }

True when the container is running. Reads whichever shape it is on: the
status string C<< $summary->state >> from C<list>, and
C<< $inspected->state->running >> from C<inspect>.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Containers> - the operations these forward to

=item * L<API::Docker::Type::ContainerSummary> - the fields C<list> returns

=item * L<API::Docker::Type::ContainerInspectResponse> - the fields
C<inspect> returns

=item * L<API::Docker::Role::Entity> - why the methods live in a role

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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

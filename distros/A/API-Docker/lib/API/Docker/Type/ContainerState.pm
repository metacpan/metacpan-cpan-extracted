package API::Docker::Type::ContainerState;
# ABSTRACT: Container's running state
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Health;
use namespace::clean;


docker status => Str,
  enum => [qw( created running paused restarting removing exited dead )];


docker running => Bool;


docker paused => Bool;


docker restarting => Bool;


docker oom_killed => Bool, wire => 'OOMKilled';


docker dead => Bool;


docker pid => Int;


docker exit_code => Int;


docker error => Str;


docker started_at => Str;


docker finished_at => Str;


docker health => 'Health';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerState - Container's running state

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerState> definition of C<spec/v1.51.yaml>.

It's part of ContainerJSONBase and will be returned by the "inspect"
command.

=head2 status

String representation of the container state. Can be one of "created",
"running", "paused", "restarting", "removing", "exited", or "dead".

=head2 running

Whether this container is running.

Note that a running container can be I<paused>. The C<Running> and C<Paused>
booleans are not mutually exclusive:

When pausing a container (on Linux), the freezer cgroup is used to suspend
all processes in the container. Freezing the process requires the process to
be running. As a result, paused containers are both C<Running> I<and>
C<Paused>.

Use the C<Status> field instead to determine if a container's state is
"running".

=head2 paused

Whether this container is paused.

=head2 restarting

Whether this container is restarting.

=head2 oom_killed

Whether a process within this container has been killed because it ran out
of memory since the container was last started. Serialised as C<OOMKilled>
-- spelled out, because deriving it from the Perl name would produce
C<OomKilled>.

=head2 dead

Undocumented upstream. The boolean beside L</status>'s C<dead> value, as
L</running>, L</paused> and L</restarting> stand beside theirs. The
swagger's example is C<false>.

=head2 pid

The process ID of this container.

=head2 exit_code

The last exit code of this container.

=head2 error

Undocumented upstream.

=head2 started_at

The time when this container was last started.

=head2 finished_at

The time when this container last exited.

=head2 health

Health stores information about the container's healthcheck results. See
L<API::Docker::Type::Health>.

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

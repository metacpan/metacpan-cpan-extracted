package API::Docker::Type::TaskStatus;
# ABSTRACT: represents the status of a task
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerStatus;
use API::Docker::Type::PortStatus;
use namespace::clean;


docker timestamp => Str, since => '1.44';


docker state => Str, since => '1.44',
  enum => [qw(
    new allocated pending assigned accepted preparing ready starting running
    complete shutdown failed rejected remove orphaned
  )];


docker message => Str, since => '1.44';


docker err => Str, since => '1.44';


docker container_status => 'ContainerStatus', since => '1.44';


docker port_status => 'PortStatus', since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskStatus - represents the status of a task

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<TaskStatus> definition of C<spec/v1.51.yaml>.

=head2 timestamp

Undocumented upstream. When L</state> was observed:
C<2016-06-07T21:07:31.290032978Z> in the swagger's C<Task> example, between
that task's L<API::Docker::Type::Task/created_at> and its
L<API::Docker::Type::Task/updated_at>.

=head2 state

Undocumented upstream. Where the task actually is, against the
L<API::Docker::Type::Task/desired_state> the orchestrator wants. Both are
C<running> in the swagger's example. The swagger enumerates C<new>,
C<allocated>, C<pending>, C<assigned>, C<accepted>, C<preparing>, C<ready>,
C<starting>, C<running>, C<complete>, C<shutdown>, C<failed>, C<rejected>,
C<remove> and C<orphaned>.

=head2 message

Undocumented upstream. Free text about that state, C<"started"> in the
swagger's C<Task> example.

=head2 err

Undocumented upstream. The failure, as text. The swagger's C<Task> example
shows a task that started and carries no C<Err> at all, only L</message>.

=head2 container_status

Represents the status of a container. See
L<API::Docker::Type::ContainerStatus>.

=head2 port_status

Represents the port status of a task's host ports whose service has
published host ports. See L<API::Docker::Type::PortStatus>.

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

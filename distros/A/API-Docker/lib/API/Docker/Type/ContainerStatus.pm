package API::Docker::Type::ContainerStatus;
# ABSTRACT: represents the status of a container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker container_id => Str, wire => 'ContainerID', since => '1.44';


docker pid => Int, wire => 'PID', since => '1.44';


docker exit_code => Int, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerStatus - represents the status of a container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerStatus> definition of C<spec/v1.51.yaml>.

=head2 container_id

Undocumented upstream. The container a swarm task is running in -- the
object hangs off L<API::Docker::Type::TaskStatus/container_status> -- and an
ordinary container ID that C<GET /containers/{id}/json> will take. The
swagger's C<Task> example carries a 64-character hex digest. Serialised as
C<ContainerID> -- spelled out, because deriving it from the Perl name would
produce C<ContainerId>.

=head2 pid

Undocumented upstream. Its process ID, the measure the swagger describes
under L<API::Docker::Type::ContainerState/pid>. C<677> in the swagger's
C<Task> example. Serialised as C<PID> -- spelled out, because deriving it
from the Perl name would produce C<Pid>.

=head2 exit_code

Undocumented upstream. Its last exit code, the measure the swagger describes
under L<API::Docker::Type::ContainerState/exit_code>. Absent from the
C<Task> example, whose container is still running.

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

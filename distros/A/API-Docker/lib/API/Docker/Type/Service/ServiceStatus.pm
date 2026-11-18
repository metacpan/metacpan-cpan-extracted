package API::Docker::Type::Service::ServiceStatus;
# ABSTRACT: The status of the service's tasks
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker running_tasks => Int;


docker desired_tasks => Int;


docker completed_tasks => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service::ServiceStatus - The status of the service's tasks

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<ServiceStatus> schema of the C<Service>
definition in C<spec/v1.51.yaml>.

Provided only when requested as part of a ServiceList operation.

=head2 running_tasks

The number of tasks for the service currently in the Running state.

=head2 desired_tasks

The number of tasks for the service desired to be running. For replicated
services, this is the replica count from the service spec. For global
services, this is computed by taking count of all tasks for the service with
a Desired State other than Shutdown.

=head2 completed_tasks

The number of tasks for a job that are in the Completed state. This field
must be cross-referenced with the service type, as the value of 0 may mean
the service is not in a job mode, or it may mean the job-mode service has no
tasks yet Completed.

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

package API::Docker::Type::Service::JobStatus;
# ABSTRACT: The status of the service when it is in one of ReplicatedJob or GlobalJob modes
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use namespace::clean;


docker job_iteration => 'ObjectVersion';


docker last_execution => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service::JobStatus - The status of the service when it is in one of ReplicatedJob or GlobalJob modes

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<JobStatus> schema of the C<Service> definition
in C<spec/v1.51.yaml>.

Absent on Replicated and Global mode services. The JobIteration is an
ObjectVersion, but unlike the Service's version, does not need to be sent
with an update request.

=head2 job_iteration

JobIteration is a value increased each time a Job is executed, successfully
or otherwise. "Executed", in this case, means the job as a whole has been
started, not that an individual Task has been launched. A job is "Executed"
when its ServiceSpec is updated. JobIteration can be used to disambiguate
Tasks belonging to different executions of a job. Though JobIteration will
increase with each subsequent execution, it may not necessarily increase by
1, and so JobIteration should not be used to. See
L<API::Docker::Type::ObjectVersion>.

=head2 last_execution

The last time, as observed by the server, that this job was started.

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

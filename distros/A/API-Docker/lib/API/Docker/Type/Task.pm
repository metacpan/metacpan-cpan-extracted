package API::Docker::Type::Task;
# ABSTRACT: One entry of the C<200> response to C<GET /tasks>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::GenericResource;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::TaskSpec;
use API::Docker::Type::TaskStatus;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker name => Str;


docker labels => { Str, Str };


docker spec => 'TaskSpec';


docker service_id => Str, wire => 'ServiceID';


docker slot => Int;


docker node_id => Str, wire => 'NodeID';


docker assigned_generic_resources => [ 'GenericResource' ];


docker status => 'TaskStatus';


docker desired_state => Str,
  enum => [qw(
    new allocated pending assigned accepted preparing ready starting running
    complete shutdown failed rejected remove orphaned
  )];


docker job_iteration => 'ObjectVersion';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Task - One entry of the C<200> response to C<GET /tasks>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Task> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /tasks> and the body of the C<200> response to
C<GET /tasks/{id}>.

=head2 id

The ID of the task. Serialised as C<ID> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Undocumented upstream. RFC 3339 with nanoseconds,
C<2016-06-07T21:07:31.171892745Z> in the swagger's example.

=head2 updated_at

Undocumented upstream. The same format, two hundred milliseconds later in
that example -- the task was created and then reported running.

=head2 name

Name of the task.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 spec

User modifiable task configuration. See L<API::Docker::Type::TaskSpec>.

=head2 service_id

The ID of the service this task is part of. Serialised as C<ServiceID> --
spelled out, because deriving it from the Perl name would produce
C<ServiceId>.

=head2 slot

Undocumented upstream. C<1> in the swagger's example, whose C<ServiceID> is
the same C<9mnpnzenvg8p8tdbtq4wvbkcz> the C<Service> example carries, and
that service asks for one replica. Read it as which replica of the service
this task is.

=head2 node_id

The ID of the node that this task is on. Serialised as C<NodeID> -- spelled
out, because deriving it from the Perl name would produce C<NodeId>.

=head2 assigned_generic_resources

User-defined resources can be either Integer resources (e.g, C<SSD=3>) or
String resources (e.g, C<GPU=UUID1>). See
L<API::Docker::Type::GenericResource>.

=head2 status

Represents the status of a task. See L<API::Docker::Type::TaskStatus>.

=head2 desired_state

Undocumented upstream. Where the orchestrator wants the task, against
L<API::Docker::Type::TaskStatus/state> which is where it actually is. Both
are C<running> in the swagger's example. The swagger enumerates C<new>,
C<allocated>, C<pending>, C<assigned>, C<accepted>, C<preparing>, C<ready>,
C<starting>, C<running>, C<complete>, C<shutdown>, C<failed>, C<rejected>,
C<remove> and C<orphaned>.

=head2 job_iteration

If the Service this Task belongs to is a job-mode service, contains the
JobIteration of the Service this Task was created for. Absent if the Task
was created for a Replicated or Global Service. See
L<API::Docker::Type::ObjectVersion>.

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

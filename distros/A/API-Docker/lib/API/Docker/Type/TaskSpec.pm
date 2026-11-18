package API::Docker::Type::TaskSpec;
# ABSTRACT: User modifiable task configuration
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::NetworkAttachmentConfig;
use API::Docker::Type::TaskSpec::ContainerSpec;
use API::Docker::Type::TaskSpec::LogDriver;
use API::Docker::Type::TaskSpec::NetworkAttachmentSpec;
use API::Docker::Type::TaskSpec::Placement;
use API::Docker::Type::TaskSpec::PluginSpec;
use API::Docker::Type::TaskSpec::Resources;
use API::Docker::Type::TaskSpec::RestartPolicy;
use namespace::clean;


docker plugin_spec => 'TaskSpec::PluginSpec';


docker container_spec => 'TaskSpec::ContainerSpec';


docker network_attachment_spec => 'TaskSpec::NetworkAttachmentSpec';


docker resources => 'TaskSpec::Resources';


docker restart_policy => 'TaskSpec::RestartPolicy';


docker placement => 'TaskSpec::Placement';


docker force_update => Int;


docker runtime => Str;


docker networks => [ 'NetworkAttachmentConfig' ];


docker log_driver => 'TaskSpec::LogDriver';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec - User modifiable task configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<TaskSpec> definition of C<spec/v1.51.yaml>.

=head2 plugin_spec

Plugin spec for the service. *(Experimental release only.)*

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::PluginSpec>.

=head2 container_spec

Container spec for the service.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::ContainerSpec>.

=head2 network_attachment_spec

Read-only spec type for non-swarm containers attached to swarm overlay
networks.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::NetworkAttachmentSpec>.

=head2 resources

Resource requirements which apply to each individual container created as
part of the service. See L<API::Docker::Type::TaskSpec::Resources>.

=head2 restart_policy

Specification for the restart policy which applies to containers created as
part of this service. See L<API::Docker::Type::TaskSpec::RestartPolicy>.

=head2 placement

Undocumented upstream. Empty (C<{}>) in both the C<Service> and the C<Task>
example, which restrict nothing. See
L<API::Docker::Type::TaskSpec::Placement>.

=head2 force_update

A counter that triggers an update even if no relevant parameters have been
changed.

=head2 runtime

Runtime is the type of runtime specified for the task executor.

=head2 networks

Specifies which networks the service should attach to. See
L<API::Docker::Type::NetworkAttachmentConfig>.

=head2 log_driver

Specifies the log driver to use for tasks created from this spec. If not
present, the default one for the swarm will be used, finally falling back to
the engine default if not specified. See
L<API::Docker::Type::TaskSpec::LogDriver>.

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

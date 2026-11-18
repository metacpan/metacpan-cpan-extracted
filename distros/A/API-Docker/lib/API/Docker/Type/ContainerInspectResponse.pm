package API::Docker::Type::ContainerInspectResponse;
# ABSTRACT: The body of the C<200> response to C<GET /containers/{id}/json>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerConfig;
use API::Docker::Type::ContainerState;
use API::Docker::Type::DriverData;
use API::Docker::Type::HostConfig;
use API::Docker::Type::MountPoint;
use API::Docker::Type::NetworkSettings;
use API::Docker::Type::OCIDescriptor;
use namespace::clean;


docker id => Str, since => '1.51';


docker created => Str, since => '1.51';


docker path => Str, since => '1.51';


docker args => [Str], since => '1.51';


docker state => 'ContainerState', since => '1.51';


docker image => Str, since => '1.51';


docker resolv_conf_path => Str, since => '1.51';


docker hostname_path => Str, since => '1.51';


docker hosts_path => Str, since => '1.51';


docker log_path => Str, since => '1.51';


docker name => Str, since => '1.51';


docker restart_count => Int, since => '1.51';


docker driver => Str, since => '1.51';


docker platform => Str, since => '1.51';


docker image_manifest_descriptor => 'OCIDescriptor', since => '1.51';


docker mount_label => Str, since => '1.51';


docker process_label => Str, since => '1.51';


docker app_armor_profile => Str, since => '1.51';


docker exec_ids => [Str], wire => 'ExecIDs', since => '1.51';


docker host_config => 'HostConfig', since => '1.51';


docker graph_driver => 'DriverData', since => '1.51';


docker size_rw => Int, since => '1.51';


docker size_root_fs => Int, since => '1.51';


docker mounts => [ 'MountPoint' ], since => '1.51';


docker config => 'ContainerConfig', since => '1.51';


docker network_settings => 'NetworkSettings', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerInspectResponse - The body of the C<200> response to C<GET /containers/{id}/json>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerInspectResponse> definition of
C<spec/v1.51.yaml>, which the swagger leaves undescribed. C<paths:> says
what it is: the body of the C<200> response to C<GET /containers/{id}/json>.

=head2 id

The ID of this container as a 128-bit (64-character) hexadecimal string (32
bytes).

=head2 created

Date and time at which the container was created, formatted in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 path

The path to the command being run.

=head2 args

The arguments to the command being run.

=head2 state

ContainerState stores container's running state. See
L<API::Docker::Type::ContainerState>.

=head2 image

The ID (digest) of the image that this container was created from.

=head2 resolv_conf_path

Location of the C</etc/resolv.conf> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=head2 hostname_path

Location of the C</etc/hostname> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=head2 hosts_path

Location of the C</etc/hosts> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=head2 log_path

Location of the file used to buffer the container's logs. Depending on the
logging-driver used for the container, this field may be omitted.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=head2 name

The name associated with this container.

For historic reasons, the name may be prefixed with a forward-slash (C</>).

=head2 restart_count

Number of times the container was restarted since it was created, or since
daemon was started.

=head2 driver

The storage-driver used for the container's filesystem (graph-driver or
snapshotter).

=head2 platform

The platform (operating system) for which the container was created.

This field was introduced for the experimental "LCOW" (Linux Containers On
Windows) features, which has been removed. In most cases, this field is
equal to the host's operating system (C<linux> or C<windows>).

=head2 image_manifest_descriptor

OCI descriptor of the platform-specific manifest of the image the container
was created from.

Note: Only available if the daemon provides a multi-platform image store.
See L<API::Docker::Type::OCIDescriptor>.

=head2 mount_label

SELinux mount label set for the container.

=head2 process_label

SELinux process label set for the container.

=head2 app_armor_profile

The AppArmor profile set for the container.

=head2 exec_ids

IDs of exec instances that are running in the container. Serialised as
C<ExecIDs> -- spelled out, because deriving it from the Perl name would
produce C<ExecIds>.

=head2 host_config

Container configuration that depends on the host we are running on. See
L<API::Docker::Type::HostConfig>.

=head2 graph_driver

Information about the storage driver used to store the container's and
image's filesystem. See L<API::Docker::Type::DriverData>.

=head2 size_rw

The size of files that have been created or changed by this container.

This field is omitted by default, and only set when size is requested in the
API request.

=head2 size_root_fs

The total size of all files in the read-only layers from the image that the
container uses. These layers can be shared between containers.

This field is omitted by default, and only set when size is requested in the
API request.

=head2 mounts

List of mounts used by the container. See L<API::Docker::Type::MountPoint>.

=head2 config

Configuration for a container that is portable between hosts. See
L<API::Docker::Type::ContainerConfig>.

=head2 network_settings

NetworkSettings exposes the network settings in the API. See
L<API::Docker::Type::NetworkSettings>.

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

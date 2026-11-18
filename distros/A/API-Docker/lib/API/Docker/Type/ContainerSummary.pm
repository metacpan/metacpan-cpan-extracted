package API::Docker::Type::ContainerSummary;
# ABSTRACT: One entry of the C<200> response to C<GET /containers/json>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerSummary::HostConfig;
use API::Docker::Type::ContainerSummary::NetworkSettings;
use API::Docker::Type::MountPoint;
use API::Docker::Type::OCIDescriptor;
use API::Docker::Type::Port;
use namespace::clean;


docker id => Str;


docker names => [Str];


docker image => Str;


docker image_id => Str, wire => 'ImageID';


docker image_manifest_descriptor => 'OCIDescriptor', since => '1.51';


docker command => Str;


docker created => Int;


docker ports => [ 'Port' ];


docker size_rw => Int;


docker size_root_fs => Int;


docker labels => { Str, Str };


docker state => Str,
  enum => [qw( created running paused restarting exited removing dead )];


docker status => Str;


docker host_config => 'ContainerSummary::HostConfig';


docker network_settings => 'ContainerSummary::NetworkSettings';


docker mounts => [ 'MountPoint' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerSummary - One entry of the C<200> response to C<GET /containers/json>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerSummary> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. C<paths:> says what it is: one entry
of the C<200> response to C<GET /containers/json> and the C<Containers>
field of the C<200> response to C<GET /system/df>.

=head2 id

The ID of this container as a 128-bit (64-character) hexadecimal string (32
bytes).

=head2 names

The names associated with this container. Most containers have a single
name, but when using legacy "links", the container can have multiple names.

For historic reasons, names are prefixed with a forward-slash (C</>).

=head2 image

The name or ID of the image used to create the container.

This field shows the image reference as was specified when creating the
container, which can be in its canonical form (e.g.,
C<docker.io/library/ubuntu:latest> or
C<docker.io/library/ubuntu@sha256:72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782>),
short form (e.g., C<ubuntu:latest>)), or the ID(-prefix) of the image (e.g.,
C<72297848456d>).

The content of this field can be updated at runtime if the image used to
create the container is untagged, in which case the field is updated to
contain the the image ID (digest) it was resolved to in its canonical,
non-truncated form (e.g.,
C<sha256:72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782>).

=head2 image_id

The ID (digest) of the image that this container was created from.
Serialised as C<ImageID> -- spelled out, because deriving it from the Perl
name would produce C<ImageId>.

=head2 image_manifest_descriptor

OCI descriptor of the platform-specific manifest of the image the container
was created from.

Note: Only available if the daemon provides a multi-platform image store.

This field is not populated in the C<GET /system/df> endpoint. See
L<API::Docker::Type::OCIDescriptor>.

=head2 command

Command to run when starting the container.

=head2 created

Date and time at which the container was created as a Unix timestamp (number
of seconds since EPOCH).

=head2 ports

Port-mappings for the container. See L<API::Docker::Type::Port>.

=head2 size_rw

The size of files that have been created or changed by this container.

This field is omitted by default, and only set when size is requested in the
API request.

=head2 size_root_fs

The total size of all files in the read-only layers from the image that the
container uses. These layers can be shared between containers.

This field is omitted by default, and only set when size is requested in the
API request.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 state

The state of this container. The swagger enumerates C<created>, C<running>,
C<paused>, C<restarting>, C<exited>, C<removing> and C<dead>.

=head2 status

Additional human-readable status of this container (e.g. C<Exit 0>).

=head2 host_config

Summary of host-specific runtime information of the container. This is a
reduced set of information in the container's "HostConfig" as available in
the container "inspect" response. See
L<API::Docker::Type::ContainerSummary::HostConfig>.

=head2 network_settings

Summary of the container's network settings. See
L<API::Docker::Type::ContainerSummary::NetworkSettings>.

=head2 mounts

List of mounts used by the container. See L<API::Docker::Type::MountPoint>.

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

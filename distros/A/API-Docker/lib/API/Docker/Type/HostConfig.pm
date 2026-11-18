package API::Docker::Type::HostConfig;
# ABSTRACT: Container configuration that depends on the host we are running on
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::HostConfig::LogConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::PortBinding;
use API::Docker::Type::RestartPolicy;
use namespace::clean;


docker_extends 'Resources';

docker binds => [Str];


docker container_id_file => Str, wire => 'ContainerIDFile';


docker log_config => 'HostConfig::LogConfig';


docker network_mode => Str;


docker port_bindings => { Str, [ 'PortBinding' ] };


docker restart_policy => 'RestartPolicy';


docker auto_remove => Bool;


docker volume_driver => Str;


docker volumes_from => [Str];


docker mounts => [ 'Mount' ];


docker console_size => [Int];


docker annotations => { Str, Str }, since => '1.44';


docker cap_add => [Str];


docker cap_drop => [Str];


docker cgroupns_mode => Str, enum => [qw( private host )];


docker dns => [Str];


docker dns_options => [Str];


docker dns_search => [Str];


docker extra_hosts => [Str];


docker group_add => [Str];


docker ipc_mode => Str;


docker cgroup => Str;


docker links => [Str];


docker oom_score_adj => Int;


docker pid_mode => Str;


docker privileged => Bool;


docker publish_all_ports => Bool;


docker readonly_rootfs => Bool;


docker security_opt => [Str];


docker storage_opt => { Str, Str };


docker tmpfs => { Str, Str };


docker uts_mode => Str, wire => 'UTSMode';


docker userns_mode => Str;


docker shm_size => Int;


docker sysctls => { Str, Str };


docker runtime => Str;


docker isolation => Str, enum => [ 'default', 'process', 'hyperv', '' ];


docker masked_paths => [Str];


docker readonly_paths => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::HostConfig - Container configuration that depends on the host we are running on

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<HostConfig> definition of C<spec/v1.51.yaml>, which is
C<allOf [ $ref Resources, { 39 properties } ]>. The reference becomes a
superclass, so a C<HostConfig> carries the 31 fields of
L<API::Docker::Type::Resources> as well as the 39 declared here -- 70 in
all. See L<API::Docker::Type/C<allOf> becomes inheritance>.

=head2 binds

A list of volume bindings for this container. Each volume binding is a
string in one of these forms:

=over 4

=item * C<host-src:container-dest[:options]> to bind-mount a host path into
the container. Both C<host-src>, and C<container-dest> must be an
I<absolute> path.

=item * C<volume-name:container-dest[:options]> to bind-mount a volume
managed by a volume driver into the container. C<container-dest> must be an
I<absolute> path.

=back

C<options> is an optional, comma-delimited list of:

=over 4

=item * C<nocopy> disables automatic copying of data from the container path
to the volume. The C<nocopy> flag only applies to named volumes.

=item * C<[ro|rw]> mounts a volume read-only or read-write, respectively. If
omitted or set to C<rw>, volumes are mounted read-write.

=item * C<[z|Z]> applies SELinux labels to allow or deny multiple containers
to read and write to the same volume. C<z>: a I<shared> content label is
applied to the content. This label indicates that multiple containers can
share the volume content, for both reading and writing. C<Z>: a I<private
unshared> label is applied to the content. This label indicates that only
the current container can use a private volume. Labeling systems such as
SELinux require proper labels to be placed on volume content that is mounted
into a container. Without a label, the security system can prevent a
container's processes from using the content. By default, the labels set by
the host operating system are not modified.

=item * C<[[r]shared|[r]slave|[r]private]> specifies mount L<propagation
behavior|https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt>.
This only applies to bind-mounted volumes, not internal volumes or named
volumes. Mount propagation requires the source mount point (the location
where the source directory is mounted in the host operating system) to have
the correct propagation properties. For shared volumes, the source mount
point must be set to C<shared>. For slave volumes, the mount must be set to
either C<shared> or C<slave>.

=back

=head2 container_id_file

Path to a file where the container ID is written. Serialised as
C<ContainerIDFile> -- spelled out, because deriving it from the Perl name
would produce C<ContainerIdFile>.

=head2 log_config

The logging configuration for this container. See
L<API::Docker::Type::HostConfig::LogConfig>.

=head2 network_mode

Network mode to use for this container. Supported standard values are:
C<bridge>, C<host>, C<none>, and C<< container:<name|id> >>. Any other value
is taken as a custom network's name to which this container should connect
to.

=head2 port_bindings

PortMap describes the mapping of container ports to host ports, using the
container's port-number and protocol as key in the format C<<
<port>/<protocol> >>, for example, C<80/udp>.

If a container's port is mapped for multiple protocols, separate entries are
added to the mapping table. In the swagger this is a C<$ref> to C<PortMap>,
a definition that is nothing but C<additionalProperties>, so it becomes a
hash here rather than a class of its own, and the daemon does answer with
C<null> for a port that is exposed but not published. See
L<API::Docker::Type::PortBinding>. B<The keys are the caller's data> and are
never translated.

=head2 restart_policy

The behavior to apply when the container exits. See
L<API::Docker::Type::RestartPolicy>.

=head2 auto_remove

Automatically remove the container when the container's process exits. This
has no effect if C<RestartPolicy> is set.

=head2 volume_driver

Driver that this container uses to mount volumes.

=head2 volumes_from

A list of volumes to inherit from another container, specified in the form
C<< <container name>[:<ro|rw>] >>.

=head2 mounts

Specification for mounts to be added to the container. See
L<API::Docker::Type::Mount>.

=head2 console_size

Initial console size, as an C<[height, width]> array.

=head2 annotations

Arbitrary non-identifying metadata attached to container and provided to the
runtime when the container is started. B<The keys are the caller's data> and
are never translated.

=head2 cap_add

A list of kernel capabilities to add to the container. Conflicts with option
'Capabilities'.

=head2 cap_drop

A list of kernel capabilities to drop from the container. Conflicts with
option 'Capabilities'.

=head2 cgroupns_mode

Cgroup namespace mode for the container. Possible values are:

=over 4

=item * C<"private">: the container runs in its own private cgroup namespace

=item * C<"host">: use the host system's cgroup namespace

=back

If not specified, the daemon default is used, which can either be
C<"private"> or C<"host">, depending on daemon version, kernel support and
configuration.

=head2 dns

A list of DNS servers for the container to use.

=head2 dns_options

A list of DNS options.

=head2 dns_search

A list of DNS search domains.

=head2 extra_hosts

A list of hostnames/IP mappings to add to the container's C</etc/hosts>
file. Specified in the form C<["hostname:IP"]>.

=head2 group_add

A list of additional groups that the container process will run as.

=head2 ipc_mode

IPC sharing mode for the container. Possible values are:

=over 4

=item * C<"none">: own private IPC namespace, with /dev/shm not mounted

=item * C<"private">: own private IPC namespace

=item * C<"shareable">: own private IPC namespace, with a possibility to
share it with other containers

=item * C<< "container:<name|id>" >>: join another (shareable) container's
IPC namespace

=item * C<"host">: use the host system's IPC namespace

=back

If not specified, daemon default is used, which can either be C<"private">
or C<"shareable">, depending on daemon version and configuration.

=head2 cgroup

Cgroup to use for the container.

=head2 links

A list of links for the container in the form C<container_name:alias>.

=head2 oom_score_adj

An integer value containing the score given to the container in order to
tune OOM killer preferences.

=head2 pid_mode

Set the PID (Process) Namespace mode for the container. It can be either:

=over 4

=item * C<< "container:<name|id>" >>: joins another container's PID
namespace

=item * C<"host">: use the host's PID namespace inside the container

=back

=head2 privileged

Gives the container full access to the host.

=head2 publish_all_ports

Allocates an ephemeral host port for all of a container's exposed ports.

Ports are de-allocated when the container stops and allocated when the
container starts. The allocated port might be changed when restarting the
container.

The port is selected from the ephemeral port range that depends on the
kernel. For example, on Linux the range is defined by
C</proc/sys/net/ipv4/ip_local_port_range>.

=head2 readonly_rootfs

Mount the container's root filesystem as read only.

=head2 security_opt

A list of string values to customize labels for MLS systems, such as
SELinux.

=head2 storage_opt

Storage driver options for this container, in the form C<{"size": "120G"}>.
B<The keys are the caller's data> and are never translated.

=head2 tmpfs

A map of container directories which should be replaced by tmpfs mounts, and
their corresponding mount options. For example:

    { "/run": "rw,noexec,nosuid,size=65536k" }

B<The keys are the caller's data> and are never translated.

=head2 uts_mode

UTS namespace to use for the container. Serialised as C<UTSMode> -- spelled
out, because deriving it from the Perl name would produce C<UtsMode>.

=head2 userns_mode

Sets the usernamespace mode for the container when usernamespace remapping
option is enabled.

=head2 shm_size

Size of C</dev/shm> in bytes. If omitted, the system uses 64MB.

=head2 sysctls

A list of kernel parameters (sysctls) to set in the container.

This field is omitted if not set. The swagger's example is C<<
{"net.ipv4.ip_forward": "1"} >>. B<The keys are the caller's data> and are
never translated.

=head2 runtime

Runtime to use with this container.

=head2 isolation

Isolation technology of the container. (Windows only). The swagger
enumerates C<default>, C<process>, C<hyperv> and the empty string.

=head2 masked_paths

The list of paths to be masked inside the container (this overrides the
default set of paths).

=head2 readonly_paths

The list of paths to be set as read-only inside the container (this
overrides the default set of paths).

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

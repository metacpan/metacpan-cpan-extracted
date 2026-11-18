package API::Docker::Type::SystemInfo;
# ABSTRACT: The body of the C<200> response to C<GET /info>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Commit;
use API::Docker::Type::ContainerdInfo;
use API::Docker::Type::DeviceInfo;
use API::Docker::Type::FirewallInfo;
use API::Docker::Type::GenericResource;
use API::Docker::Type::PluginsInfo;
use API::Docker::Type::RegistryServiceConfig;
use API::Docker::Type::Runtime;
use API::Docker::Type::SwarmInfo;
use API::Docker::Type::SystemInfo::DefaultAddressPool;
use namespace::clean;


docker id => Str, wire => 'ID';


docker containers => Int;


docker containers_running => Int;


docker containers_paused => Int;


docker containers_stopped => Int;


docker images => Int;


docker driver => Str;


docker driver_status => [[Str]];


docker docker_root_dir => Str;


docker plugins => 'PluginsInfo';


docker memory_limit => Bool;


docker swap_limit => Bool;


docker kernel_memory_tcp => Bool, wire => 'KernelMemoryTCP';


docker cpu_cfs_period => Bool;


docker cpu_cfs_quota => Bool;


docker cpu_shares => Bool, wire => 'CPUShares';


docker cpu_set => Bool, wire => 'CPUSet';


docker pids_limit => Bool;


docker oom_kill_disable => Bool;


docker ipv4_forwarding => Bool, wire => 'IPv4Forwarding';


docker debug => Bool;


docker n_fd => Int;


docker n_goroutines => Int;


docker system_time => Str;


docker logging_driver => Str;


docker cgroup_driver => Str, enum => [qw( cgroupfs systemd none )];


docker cgroup_version => Str, enum => [qw( 1 2 )];


docker n_events_listener => Int;


docker kernel_version => Str;


docker operating_system => Str;


docker os_version => Str, wire => 'OSVersion';


docker os_type => Str, wire => 'OSType';


docker architecture => Str;


docker n_cpu => Int, wire => 'NCPU';


docker mem_total => Int;


docker index_server_address => Str;


docker registry_config => 'RegistryServiceConfig';


docker generic_resources => [ 'GenericResource' ];


docker http_proxy => Str;


docker https_proxy => Str;


docker no_proxy => Str;


docker name => Str;


docker labels => [Str];


docker experimental_build => Bool;


docker server_version => Str;


docker runtimes => { Str, 'Runtime' };


docker default_runtime => Str;


docker swarm => 'SwarmInfo';


docker live_restore_enabled => Bool;


docker isolation => Str, enum => [ 'default', 'hyperv', 'process', '' ];


docker init_binary => Str;


docker containerd_commit => 'Commit';


docker runc_commit => 'Commit';


docker init_commit => 'Commit';


docker security_options => [Str];


docker product_license => Str;


docker default_address_pools => [ 'SystemInfo::DefaultAddressPool' ];


docker firewall_backend => 'FirewallInfo', since => '1.51';


docker discovered_devices => [ 'DeviceInfo' ], since => '1.51';


docker warnings => [Str];


docker cdi_spec_dirs => [Str], wire => 'CDISpecDirs', since => '1.44';


docker containerd => 'ContainerdInfo', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SystemInfo - The body of the C<200> response to C<GET /info>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<SystemInfo> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of the
C<200> response to C<GET /info>.

=head2 id

Unique identifier of the daemon.

> B<Note>: The format of the ID itself is not part of the API, and > should
not be considered stable. Serialised as C<ID> -- spelled out, because
deriving it from the Perl name would produce C<Id>.

=head2 containers

Total number of containers on the host.

=head2 containers_running

Number of containers with status C<"running">.

=head2 containers_paused

Number of containers with status C<"paused">.

=head2 containers_stopped

Number of containers with status C<"stopped">.

=head2 images

Total number of images on the host.

Both I<tagged> and I<untagged> (dangling) images are counted.

=head2 driver

Name of the storage driver in use.

=head2 driver_status

Information specific to the storage driver, provided as "label" / "value"
pairs.

This information is provided by the storage driver, and formatted in a way
consistent with the output of C<docker info> on the command line.

> B<Note>: The information returned in this field, including the >
formatting of values and labels, should not be considered stable, > and may
change without notice.

=head2 docker_root_dir

Root directory of persistent Docker state.

Defaults to C</var/lib/docker> on Linux, and C<C:\ProgramData\docker> on
Windows.

=head2 plugins

Available plugins per type. See L<API::Docker::Type::PluginsInfo>.

=head2 memory_limit

Indicates if the host has memory limit support enabled.

=head2 swap_limit

Indicates if the host has memory swap limit support enabled.

=head2 kernel_memory_tcp

Indicates if the host has kernel memory TCP limit support enabled. This
field is omitted if not supported.

Kernel memory TCP limits are not supported when using cgroups v2, which does
not support the corresponding C<memory.kmem.tcp.limit_in_bytes> cgroup.

B<Deprecated>: This field is deprecated as kernel 6.12 has deprecated kernel
memory TCP accounting. Serialised as C<KernelMemoryTCP> -- spelled out,
because deriving it from the Perl name would produce C<KernelMemoryTcp>.

=head2 cpu_cfs_period

Indicates if CPU CFS(Completely Fair Scheduler) period is supported by the
host.

=head2 cpu_cfs_quota

Indicates if CPU CFS(Completely Fair Scheduler) quota is supported by the
host.

=head2 cpu_shares

Indicates if CPU Shares limiting is supported by the host. Serialised as
C<CPUShares> -- spelled out, because deriving it from the Perl name would
produce C<CpuShares>.

=head2 cpu_set

Indicates if CPUsets (cpuset.cpus, cpuset.mems) are supported by the host.

See
L<cpuset(7)|https://www.kernel.org/doc/Documentation/cgroup-v1/cpusets.txt>
Serialised as C<CPUSet> -- spelled out, because deriving it from the Perl
name would produce C<CpuSet>.

=head2 pids_limit

Indicates if the host kernel has PID limit support enabled.

=head2 oom_kill_disable

Indicates if OOM killer disable is supported on the host.

=head2 ipv4_forwarding

Indicates IPv4 forwarding is enabled. Serialised as C<IPv4Forwarding> --
spelled out, because deriving it from the Perl name would produce
C<Ipv4Forwarding>.

=head2 debug

Indicates if the daemon is running in debug-mode / with debug-level logging
enabled.

=head2 n_fd

The total number of file Descriptors in use by the daemon process.

This information is only returned if debug-mode is enabled.

=head2 n_goroutines

The number of goroutines that currently exist.

This information is only returned if debug-mode is enabled.

=head2 system_time

Current system-time in L<RFC 3339|https://www.ietf.org/rfc/rfc3339.txt>
format with nano-seconds.

=head2 logging_driver

The logging driver to use as a default for new containers.

=head2 cgroup_driver

The driver to use for managing cgroups. The swagger enumerates C<cgroupfs>,
C<systemd> and C<none>. The daemon defaults it to cgroupfs.

=head2 cgroup_version

The version of the cgroup. The swagger enumerates C<1> and C<2>. The daemon
defaults it to 1.

=head2 n_events_listener

Number of event listeners subscribed.

=head2 kernel_version

Kernel version of the host.

On Linux, this information obtained from C<uname>. On Windows this
information is queried from the
C<HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\>
registry value, for example _"10.0 14393
(14393.1198.amd64fre.rs1_release_sec.170427-1353)"_.

=head2 operating_system

Name of the host's operating system, for example: "Ubuntu 24.04 LTS" or
"Windows Server 2016 Datacenter".

=head2 os_version

Version of the host's operating system

> B<Note>: The information returned in this field, including its > very
existence, and the formatting of values, should not be considered > stable,
and may change without notice. Serialised as C<OSVersion> -- spelled out,
because deriving it from the Perl name would produce C<OsVersion>.

=head2 os_type

Generic type of the operating system of the host, as returned by the Go
runtime (C<GOOS>).

Currently returned values are "linux" and "windows". A full list of possible
values can be found in the L<Go
documentation|https://go.dev/doc/install/source#environment>. Serialised as
C<OSType> -- spelled out, because deriving it from the Perl name would
produce C<OsType>.

=head2 architecture

Hardware architecture of the host, as returned by the operating system. This
is equivalent to the output of C<uname -m> on Linux.

Unlike C<Arch> (from C</version>), this reports the machine's native
architecture, which can differ from the Go runtime architecture when running
a binary compiled for a different architecture (for example, a 32-bit binary
running on 64-bit hardware).

=head2 n_cpu

The number of logical CPUs usable by the daemon.

The number of available CPUs is checked by querying the operating system
when the daemon starts. Changes to operating system CPU allocation after the
daemon is started are not reflected. Serialised as C<NCPU> -- spelled out,
because deriving it from the Perl name would produce C<NCpu>.

=head2 mem_total

Total amount of physical memory available on the host, in bytes.

=head2 index_server_address

Address / URL of the index server that is used for image search, and as a
default for user authentication for Docker Hub and Docker Cloud.

=head2 registry_config

RegistryServiceConfig stores daemon registry services configuration. See
L<API::Docker::Type::RegistryServiceConfig>.

=head2 generic_resources

User-defined resources can be either Integer resources (e.g, C<SSD=3>) or
String resources (e.g, C<GPU=UUID1>). See
L<API::Docker::Type::GenericResource>.

=head2 http_proxy

HTTP-proxy configured for the daemon. This value is obtained from the
L<C<HTTP_PROXY>|https://www.gnu.org/software/wget/manual/html_node/Proxies.html>
environment variable. Credentials (L<user info
component|https://tools.ietf.org/html/rfc3986#section-3.2.1>) in the proxy
URL are masked in the API response.

Containers do not automatically inherit this configuration.

=head2 https_proxy

HTTPS-proxy configured for the daemon. This value is obtained from the
L<C<HTTPS_PROXY>|https://www.gnu.org/software/wget/manual/html_node/Proxies.html>
environment variable. Credentials (L<user info
component|https://tools.ietf.org/html/rfc3986#section-3.2.1>) in the proxy
URL are masked in the API response.

Containers do not automatically inherit this configuration.

=head2 no_proxy

Comma-separated list of domain extensions for which no proxy should be used.
This value is obtained from the
L<C<NO_PROXY>|https://www.gnu.org/software/wget/manual/html_node/Proxies.html>
environment variable.

Containers do not automatically inherit this configuration.

=head2 name

Hostname of the host.

=head2 labels

User-defined labels (key/value metadata) as set on the daemon.

> B<Note>: When part of a Swarm, nodes can both have I<daemon> labels, > set
through the daemon configuration, and I<node> labels, set from a > manager
node in the Swarm. Node labels are not included in this > field. Node labels
can be retrieved using the C</nodes/(id)> endpoint > on a manager node in
the Swarm.

=head2 experimental_build

Indicates if experimental features are enabled on the daemon.

=head2 server_version

Version string of the daemon.

=head2 runtimes

List of L<OCI compliant|https://github.com/opencontainers/runtime-spec>
runtimes configured on the daemon. Keys hold the "name" used to reference
the runtime.

The Docker daemon relies on an OCI compliant runtime (invoked via the
C<containerd> daemon) as its interface to the Linux kernel namespaces,
cgroups, and SELinux.

The default runtime is C<runc>, and automatically configured. Additional
runtimes can be configured by the user and will be listed here. See
L<API::Docker::Type::Runtime>. B<The keys are the caller's data> and are
never translated.

=head2 default_runtime

Name of the default OCI runtime that is used when starting containers.

The default can be overridden per-container at create time.

=head2 swarm

Represents generic information about swarm. See
L<API::Docker::Type::SwarmInfo>.

=head2 live_restore_enabled

Indicates if live restore is enabled.

If enabled, containers are kept running when the daemon is shutdown or upon
daemon start if running containers are detected. The daemon defaults it to
false.

=head2 isolation

Represents the isolation technology to use as a default for containers. The
supported values are platform-specific.

If no isolation value is specified on daemon start, on Windows client, the
default is C<hyperv>, and on Windows server, the default is C<process>.

This option is currently not used on other platforms.

=head2 init_binary

Name and, optional, path of the C<docker-init> binary.

If the path is omitted, the daemon searches the host's C<$PATH> for the
binary and uses the first result.

=head2 containerd_commit

Commit holds the Git-commit (SHA1) that a binary was built from, as reported
in the version-string of external tools, such as C<containerd>, or C<runC>.
See L<API::Docker::Type::Commit>.

=head2 runc_commit

Commit holds the Git-commit (SHA1) that a binary was built from, as reported
in the version-string of external tools, such as C<containerd>, or C<runC>.
See L<API::Docker::Type::Commit>.

=head2 init_commit

Commit holds the Git-commit (SHA1) that a binary was built from, as reported
in the version-string of external tools, such as C<containerd>, or C<runC>.
See L<API::Docker::Type::Commit>.

=head2 security_options

List of security features that are enabled on the daemon, such as apparmor,
seccomp, SELinux, user-namespaces (userns), rootless and no-new-privileges.

Additional configuration options for each security feature may be present,
and are included as a comma-separated list of key/value pairs.

=head2 product_license

Reports a summary of the product license on the daemon.

If a commercial license has been applied to the daemon, information such as
number of nodes, and expiration are included.

=head2 default_address_pools

List of custom default address pools for local networks, which can be
specified in the daemon.json file or dockerd option.

Example: a Base "10.10.0.0/16" with Size 24 will define the set of 256
10.10.[0-255].0/24 address pools. See
L<API::Docker::Type::SystemInfo::DefaultAddressPool>.

=head2 firewall_backend

Information about the daemon's firewalling configuration. See
L<API::Docker::Type::FirewallInfo>.

=head2 discovered_devices

List of devices discovered by device drivers.

Each device includes information about its source driver, kind, name, and
additional driver-specific attributes. See L<API::Docker::Type::DeviceInfo>.

=head2 warnings

List of warnings / informational messages about missing features, or issues
related to the daemon configuration.

These messages can be printed by the client as information to the user.

=head2 cdi_spec_dirs

List of directories where (Container Device Interface) CDI specifications
are located.

These specifications define vendor-specific modifications to an OCI runtime
specification for a container being created.

An empty list indicates that CDI device injection is disabled.

Note that since using CDI device injection requires the daemon to have
experimental enabled. For non-experimental daemons an empty list will always
be returned. Serialised as C<CDISpecDirs> -- spelled out, because deriving
it from the Perl name would produce C<CdiSpecDirs>.

=head2 containerd

Information for connecting to the containerd instance that is used by the
daemon. See L<API::Docker::Type::ContainerdInfo>.

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

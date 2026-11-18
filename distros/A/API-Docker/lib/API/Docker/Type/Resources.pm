package API::Docker::Type::Resources;
# ABSTRACT: A container's resources (cgroups config, ulimits, etc)
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::DeviceMapping;
use API::Docker::Type::DeviceRequest;
use API::Docker::Type::Resources::BlkioWeightDevice;
use API::Docker::Type::Resources::Ulimit;
use API::Docker::Type::ThrottleDevice;
use namespace::clean;


docker cpu_shares => Int;


docker memory => Int;


docker cgroup_parent => Str;


docker blkio_weight => Int;


docker blkio_weight_device => [ 'Resources::BlkioWeightDevice' ];


docker blkio_device_read_bps => [ 'ThrottleDevice' ];


docker blkio_device_write_bps => [ 'ThrottleDevice' ];


docker blkio_device_read_iops => [ 'ThrottleDevice' ],
  wire => 'BlkioDeviceReadIOps';


docker blkio_device_write_iops => [ 'ThrottleDevice' ],
  wire => 'BlkioDeviceWriteIOps';


docker cpu_period => Int;


docker cpu_quota => Int;


docker cpu_realtime_period => Int;


docker cpu_realtime_runtime => Int;


docker cpuset_cpus => Str;


docker cpuset_mems => Str;


docker devices => [ 'DeviceMapping' ];


docker device_cgroup_rules => [Str];


docker device_requests => [ 'DeviceRequest' ];


docker kernel_memory_tcp => Int, wire => 'KernelMemoryTCP';


docker memory_reservation => Int;


docker memory_swap => Int;


docker memory_swappiness => Int;


docker nano_cpus => Int;


docker oom_kill_disable => Bool;


docker init => Bool;


docker pids_limit => Int;


docker ulimits => [ 'Resources::Ulimit' ];


docker cpu_count => Int;


docker cpu_percent => Int;


docker io_maximum_iops => Int, wire => 'IOMaximumIOps';


docker io_maximum_bandwidth => Int, wire => 'IOMaximumBandwidth';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Resources - A container's resources (cgroups config, ulimits, etc)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Resources> definition of C<spec/v1.51.yaml>.

L<API::Docker::Type::HostConfig> is C<allOf [ $ref Resources, ... ]> in the
swagger and therefore inherits from this class, which is why every field
below is also a field of a C<HostConfig>. C<TaskSpec> references the
definition directly.

=head2 cpu_shares

An integer value representing this container's relative CPU weight versus
other containers.

=head2 memory

Memory limit in bytes. The daemon defaults it to 0.

=head2 cgroup_parent

Path to C<cgroups> under which the container's C<cgroup> is created. If the
path is not absolute, the path is considered to be relative to the
C<cgroups> path of the init process. Cgroups are created if they do not
already exist.

=head2 blkio_weight

Block IO weight (relative weight).

=head2 blkio_weight_device

Block IO weight (relative device weight) in the form:

    [{"Path": "device_path", "Weight": weight}]

See L<API::Docker::Type::Resources::BlkioWeightDevice>.

=head2 blkio_device_read_bps

Limit read rate (bytes per second) from a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>.

=head2 blkio_device_write_bps

Limit write rate (bytes per second) to a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>.

=head2 blkio_device_read_iops

Limit read rate (IO per second) from a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>. Serialised as
C<BlkioDeviceReadIOps> -- spelled out, because deriving it from the Perl
name would produce C<BlkioDeviceReadIops>.

=head2 blkio_device_write_iops

Limit write rate (IO per second) to a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>. Serialised as
C<BlkioDeviceWriteIOps> -- spelled out, because deriving it from the Perl
name would produce C<BlkioDeviceWriteIops>.

=head2 cpu_period

The length of a CPU period in microseconds.

=head2 cpu_quota

Microseconds of CPU time that the container can get in a CPU period.

=head2 cpu_realtime_period

The length of a CPU real-time period in microseconds. Set to 0 to allocate
no time allocated to real-time tasks.

=head2 cpu_realtime_runtime

The length of a CPU real-time runtime in microseconds. Set to 0 to allocate
no time allocated to real-time tasks.

=head2 cpuset_cpus

CPUs in which to allow execution (e.g., C<0-3>, C<0,1>).

=head2 cpuset_mems

Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective
on NUMA systems.

=head2 devices

A list of devices to add to the container. See
L<API::Docker::Type::DeviceMapping>.

=head2 device_cgroup_rules

A list of cgroup rules to apply to the container.

=head2 device_requests

A list of requests for devices to be sent to device drivers. See
L<API::Docker::Type::DeviceRequest>.

=head2 kernel_memory_tcp

Hard limit for kernel TCP buffer memory (in bytes). Depending on the OCI
runtime in use, this option may be ignored. It is no longer supported by the
default (runc) runtime.

This field is omitted when empty.

B<Deprecated>: This field is deprecated as kernel 6.12 has deprecated
C<memory.kmem.tcp.limit_in_bytes> field for cgroups v1. This field will be
removed in a future release. Serialised as C<KernelMemoryTCP> -- spelled
out, because deriving it from the Perl name would produce
C<KernelMemoryTcp>.

=head2 memory_reservation

Memory soft limit in bytes.

=head2 memory_swap

Total memory limit (memory + swap). Set as C<-1> to enable unlimited swap.

=head2 memory_swappiness

Tune a container's memory swappiness behavior. Accepts an integer between 0
and 100.

=head2 nano_cpus

CPU quota in units of 10^-9 CPUs.

=head2 oom_kill_disable

Disable OOM Killer for the container.

=head2 init

Run an init inside the container that forwards signals and reaps processes.
This field is omitted if empty, and the default (as configured on the
daemon) is used.

=head2 pids_limit

Tune a container's PIDs limit. Set C<0> or C<-1> for unlimited, or C<null>
to not change.

=head2 ulimits

A list of resource limits to set in the container. For example:

    {"Name": "nofile", "Soft": 1024, "Hard": 2048}

See L<API::Docker::Type::Resources::Ulimit>.

=head2 cpu_count

The number of usable CPUs (Windows only).

On Windows Server containers, the processor resource controls are mutually
exclusive. The order of precedence is C<CPUCount> first, then C<CPUShares>,
and C<CPUPercent> last.

=head2 cpu_percent

The usable percentage of the available CPUs (Windows only).

On Windows Server containers, the processor resource controls are mutually
exclusive. The order of precedence is C<CPUCount> first, then C<CPUShares>,
and C<CPUPercent> last.

=head2 io_maximum_iops

Maximum IOps for the container system drive (Windows only). Serialised as
C<IOMaximumIOps> -- spelled out, because deriving it from the Perl name
would produce C<IoMaximumIops>.

=head2 io_maximum_bandwidth

Maximum IO in bytes per second for the container system drive (Windows
only). Serialised as C<IOMaximumBandwidth> -- spelled out, because deriving
it from the Perl name would produce C<IoMaximumBandwidth>.

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

#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unexpected systemd parameter. Please contact cme author to update systemd model.'
      }
    ],
    'class_description' => 'Unit configuration files for services, slices, scopes, sockets, mount points, and swap devices share a subset
of configuration options for resource control of spawned processes. Internally, this relies on the Linux Control
Groups (cgroups) kernel concept for organizing processes in a hierarchical tree of named groups for the purpose of
resource management.

This man page lists the configuration options shared by
those six unit types. See
L<systemd.unit(5)>
for the common options of all unit configuration files, and
L<systemd.slice(5)>,
L<systemd.scope(5)>,
L<systemd.service(5)>,
L<systemd.socket(5)>,
L<systemd.mount(5)>,
and
L<systemd.swap(5)>
for more information on the specific unit configuration files. The
resource control configuration options are configured in the
[Slice], [Scope], [Service], [Socket], [Mount], or [Swap]
sections, depending on the unit type.

In addition, options which control resources available to programs
executed by systemd are listed in
L<systemd.exec(5)>.
Those options complement options listed here.

See the L<New
Control Group Interfaces|https://www.freedesktop.org/wiki/Software/systemd/ControlGroupInterface> for an introduction on how to make
use of resource control APIs from programs.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'CPUAccounting',
      {
        'description' => 'Turn on CPU usage accounting for this unit. Takes a
boolean argument. Note that turning on CPU accounting for
one unit will also implicitly turn it on for all units
contained in the same slice and for all its parent slices
and the units contained therein. The system default for this
setting may be controlled with
C<DefaultCPUAccounting> in
L<systemd-system.conf(5)>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'CPUWeight',
      {
        'description' => 'These options accept an integer value or a the special string "idle":

While C<StartupCPUWeight> applies to the startup and shutdown phases of the system,
C<CPUWeight> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupCPUWeight> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartupCPUWeight',
      {
        'description' => 'These options accept an integer value or a the special string "idle":

While C<StartupCPUWeight> applies to the startup and shutdown phases of the system,
C<CPUWeight> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupCPUWeight> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CPUQuota',
      {
        'description' => 'Assign the specified CPU time quota to the processes executed. Takes a percentage value, suffixed with
"%". The percentage specifies how much CPU time the unit shall get at maximum, relative to the total CPU time
available on one CPU. Use values > 100% for allotting CPU time on more than one CPU. This controls the
C<cpu.max> attribute on the unified control group hierarchy and
C<cpu.cfs_quota_us> on legacy. For details about these control group attributes, see L<Control Groups v2|https://docs.kernel.org/admin-guide/cgroup-v2.html> and L<CFS Bandwidth Control|https://docs.kernel.org/scheduler/sched-bwc.html>.
Setting C<CPUQuota> to an empty value unsets the quota.

Example: C<CPUQuota=20%> ensures that the executed processes will never get more than
20% CPU time on one CPU.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CPUQuotaPeriodSec',
      {
        'description' => 'Assign the duration over which the CPU time quota specified by C<CPUQuota> is measured.
Takes a time duration value in seconds, with an optional suffix such as "ms" for milliseconds (or "s" for seconds.)
The default setting is 100ms. The period is clamped to the range supported by the kernel, which is [1ms, 1000ms].
Additionally, the period is adjusted up so that the quota interval is also at least 1ms.
Setting C<CPUQuotaPeriodSec> to an empty value resets it to the default.

This controls the second field of C<cpu.max> attribute on the unified control group hierarchy
and C<cpu.cfs_period_us> on legacy. For details about these control group attributes, see
L<Control Groups v2|https://docs.kernel.org/admin-guide/cgroup-v2.html> and
L<CFS Scheduler|https://docs.kernel.org/scheduler/sched-design-CFS.html>.

Example: C<CPUQuotaPeriodSec=10ms> to request that the CPU quota is measured in periods of 10ms.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AllowedCPUs',
      {
        'description' => 'Restrict processes to be executed on specific CPUs. Takes a list of CPU indices or ranges separated by either
whitespace or commas. CPU ranges are specified by the lower and upper CPU indices separated by a dash.

Setting C<AllowedCPUs> or C<StartupAllowedCPUs> doesn\'t guarantee that all
of the CPUs will be used by the processes as it may be limited by parent units. The effective configuration is
reported as C<EffectiveCPUs>.

While C<StartupAllowedCPUs> applies to the startup and shutdown phases of the system,
C<AllowedCPUs> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupAllowedCPUs> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.

This setting is supported only with the unified control group hierarchy.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartupAllowedCPUs',
      {
        'description' => 'Restrict processes to be executed on specific CPUs. Takes a list of CPU indices or ranges separated by either
whitespace or commas. CPU ranges are specified by the lower and upper CPU indices separated by a dash.

Setting C<AllowedCPUs> or C<StartupAllowedCPUs> doesn\'t guarantee that all
of the CPUs will be used by the processes as it may be limited by parent units. The effective configuration is
reported as C<EffectiveCPUs>.

While C<StartupAllowedCPUs> applies to the startup and shutdown phases of the system,
C<AllowedCPUs> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupAllowedCPUs> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.

This setting is supported only with the unified control group hierarchy.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AllowedMemoryNodes',
      {
        'description' => 'Restrict processes to be executed on specific memory NUMA nodes. Takes a list of memory NUMA nodes indices
or ranges separated by either whitespace or commas. Memory NUMA nodes ranges are specified by the lower and upper
NUMA nodes indices separated by a dash.

Setting C<AllowedMemoryNodes> or C<StartupAllowedMemoryNodes> doesn\'t
guarantee that all of the memory NUMA nodes will be used by the processes as it may be limited by parent units.
The effective configuration is reported as C<EffectiveMemoryNodes>.

While C<StartupAllowedMemoryNodes> applies to the startup and shutdown phases of the system,
C<AllowedMemoryNodes> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupAllowedMemoryNodes> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.

This setting is supported only with the unified control group hierarchy.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartupAllowedMemoryNodes',
      {
        'description' => 'Restrict processes to be executed on specific memory NUMA nodes. Takes a list of memory NUMA nodes indices
or ranges separated by either whitespace or commas. Memory NUMA nodes ranges are specified by the lower and upper
NUMA nodes indices separated by a dash.

Setting C<AllowedMemoryNodes> or C<StartupAllowedMemoryNodes> doesn\'t
guarantee that all of the memory NUMA nodes will be used by the processes as it may be limited by parent units.
The effective configuration is reported as C<EffectiveMemoryNodes>.

While C<StartupAllowedMemoryNodes> applies to the startup and shutdown phases of the system,
C<AllowedMemoryNodes> applies to normal runtime of the system, and if the former is not set also to
the startup and shutdown phases. Using C<StartupAllowedMemoryNodes> allows prioritizing specific services at
boot-up and shutdown differently than during normal runtime.

This setting is supported only with the unified control group hierarchy.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MemoryAccounting',
      {
        'description' => 'Turn on process and kernel memory accounting for this
unit. Takes a boolean argument. Note that turning on memory
accounting for one unit will also implicitly turn it on for
all units contained in the same slice and for all its parent
slices and the units contained therein. The system default
for this setting may be controlled with
C<DefaultMemoryAccounting> in
L<systemd-system.conf(5)>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'MemoryMin',
      {
        'description' => 'Specify the memory usage protection of the executed processes in this unit.
When reclaiming memory, the unit is treated as if it was using less memory resulting in memory
to be preferentially reclaimed from unprotected units.
Using C<MemoryLow> results in a weaker protection where memory may still
be reclaimed to avoid invoking the OOM killer in case there is no other reclaimable memory.

For a protection to be effective, it is generally required to set a corresponding
allocation on all ancestors, which is then distributed between children
(with the exception of the root slice).
Any C<MemoryMin> or C<MemoryLow> allocation that is not
explicitly distributed to specific children is used to create a shared protection for all children.
As this is a shared protection, the children will freely compete for the memory.

Takes a memory size in bytes. If the value is suffixed with K, M, G or T, the specified memory size is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes (with the base 1024), respectively. Alternatively, a
percentage value may be specified, which is taken relative to the installed physical memory on the
system. If assigned the special value C<infinity>, all available memory is protected, which may be
useful in order to always inherit all of the protection afforded by ancestors.
This controls the C<memory.min> or C<memory.low> control group attribute.
For details about this control group attribute, see L<Memory Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#memory-interface-files>.

Units may have their children use a default C<memory.min> or
C<memory.low> value by specifying C<DefaultMemoryMin> or
C<DefaultMemoryLow>, which has the same semantics as
C<MemoryMin> and C<MemoryLow>.
This setting does not affect C<memory.min> or C<memory.low>
in the unit itself.
Using it to set a default child allocation is only useful on kernels older than 5.7,
which do not support the C<memory_recursiveprot> cgroup2 mount option.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MemoryHigh',
      {
        'description' => 'Specify the throttling limit on memory usage of the executed processes in this unit. Memory usage may go
above the limit if unavoidable, but the processes are heavily slowed down and memory is taken away
aggressively in such cases. This is the main mechanism to control memory usage of a unit.

Takes a memory size in bytes. If the value is suffixed with K, M, G or T, the specified memory size is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes (with the base 1024), respectively. Alternatively, a
percentage value may be specified, which is taken relative to the installed physical memory on the
system. If assigned the
special value C<infinity>, no memory throttling is applied. This controls the
C<memory.high> control group attribute. For details about this control group attribute, see
L<Memory Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#memory-interface-files>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MemoryMax',
      {
        'description' => 'Specify the absolute limit on memory usage of the executed processes in this unit. If memory usage
cannot be contained under the limit, out-of-memory killer is invoked inside the unit. It is recommended to
use C<MemoryHigh> as the main control mechanism and use C<MemoryMax> as the
last line of defense.

Takes a memory size in bytes. If the value is suffixed with K, M, G or T, the specified memory size is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes (with the base 1024), respectively. Alternatively, a
percentage value may be specified, which is taken relative to the installed physical memory on the system. If
assigned the special value C<infinity>, no memory limit is applied. This controls the
C<memory.max> control group attribute. For details about this control group attribute, see
L<Memory Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#memory-interface-files>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MemorySwapMax',
      {
        'description' => 'Specify the absolute limit on swap usage of the executed processes in this unit.

Takes a swap size in bytes. If the value is suffixed with K, M, G or T, the specified swap size is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes (with the base 1024), respectively. If assigned the
special value C<infinity>, no swap limit is applied. This controls the
C<memory.swap.max> control group attribute. For details about this control group attribute,
see L<Memory Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#memory-interface-files>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TasksAccounting',
      {
        'description' => 'Turn on task accounting for this unit. Takes a
boolean argument. If enabled, the system manager will keep
track of the number of tasks in the unit. The number of
tasks accounted this way includes both kernel threads and
userspace processes, with each thread counting
individually. Note that turning on tasks accounting for one
unit will also implicitly turn it on for all units contained
in the same slice and for all its parent slices and the
units contained therein. The system default for this setting
may be controlled with
C<DefaultTasksAccounting> in
L<systemd-system.conf(5)>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'TasksMax',
      {
        'description' => 'Specify the maximum number of tasks that may be created in the unit. This ensures that the
number of tasks accounted for the unit (see above) stays below a specific limit. This either takes
an absolute number of tasks or a percentage value that is taken relative to the configured maximum
number of tasks on the system. If assigned the special value C<infinity>, no tasks
limit is applied. This controls the C<pids.max> control group attribute. For
details about this control group attribute, the
L<pids controller
|https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#pid>.

The system default for this setting may be controlled with
C<DefaultTasksMax> in
L<systemd-system.conf(5)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOAccounting',
      {
        'description' => 'Turn on Block I/O accounting for this unit, if the unified control group hierarchy is used on the
system. Takes a boolean argument. Note that turning on block I/O accounting for one unit will also implicitly
turn it on for all units contained in the same slice and all for its parent slices and the units contained
therein. The system default for this setting may be controlled with C<DefaultIOAccounting>
in
L<systemd-system.conf(5)>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'IOWeight',
      {
        'description' => 'Set the default overall block I/O weight for the executed processes, if the unified control
group hierarchy is used on the system. Takes a single weight value (between 1 and 10000) to set the
default block I/O weight. This controls the C<io.weight> control group attribute,
which defaults to 100. For details about this control group attribute, see L<IO
Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.  The available I/O bandwidth is split up among all units within one slice
relative to their block I/O weight. A higher weight means more I/O bandwidth, a lower weight means
less.

While C<StartupIOWeight> applies
to the startup and shutdown phases of the system,
C<IOWeight> applies to the later runtime of
the system, and if the former is not set also to the startup
and shutdown phases. This allows prioritizing specific services at boot-up
and shutdown differently than during runtime.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartupIOWeight',
      {
        'description' => 'Set the default overall block I/O weight for the executed processes, if the unified control
group hierarchy is used on the system. Takes a single weight value (between 1 and 10000) to set the
default block I/O weight. This controls the C<io.weight> control group attribute,
which defaults to 100. For details about this control group attribute, see L<IO
Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.  The available I/O bandwidth is split up among all units within one slice
relative to their block I/O weight. A higher weight means more I/O bandwidth, a lower weight means
less.

While C<StartupIOWeight> applies
to the startup and shutdown phases of the system,
C<IOWeight> applies to the later runtime of
the system, and if the former is not set also to the startup
and shutdown phases. This allows prioritizing specific services at boot-up
and shutdown differently than during runtime.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IODeviceWeight',
      {
        'description' => 'Set the per-device overall block I/O weight for the executed processes, if the unified control group
hierarchy is used on the system. Takes a space-separated pair of a file path and a weight value to specify
the device specific weight value, between 1 and 10000. (Example: C</dev/sda 1000>). The file
path may be specified as path to a block device node or as any other file, in which case the backing block
device of the file system of the file is determined. This controls the C<io.weight> control
group attribute, which defaults to 100. Use this option multiple times to set weights for multiple devices.
For details about this control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

The specified device node should reference a block device that has an I/O scheduler
associated, i.e. should not refer to partition or loopback block devices, but to the originating,
physical device. When a path to a regular file or directory is specified it is attempted to
discover the correct originating device backing the file system of the specified path. This works
correctly only for simpler cases, where the file system is directly placed on a partition or
physical block device, or where simple 1:1 encryption using dm-crypt/LUKS is used. This discovery
does not cover complex storage and in particular RAID and volume management storage devices.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOReadBandwidthMax',
      {
        'description' => 'Set the per-device overall block I/O bandwidth maximum limit for the executed processes, if the unified
control group hierarchy is used on the system. This limit is not work-conserving and the executed processes
are not allowed to use more even if the device has idle capacity.  Takes a space-separated pair of a file
path and a bandwidth value (in bytes per second) to specify the device specific bandwidth. The file path may
be a path to a block device node, or as any other file in which case the backing block device of the file
system of the file is used. If the bandwidth is suffixed with K, M, G, or T, the specified bandwidth is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes, respectively, to the base of 1000. (Example:
"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 5M"). This controls the C<io.max> control
group attributes. Use this option multiple times to set bandwidth limits for multiple devices. For details
about this control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

Similar restrictions on block device discovery as for C<IODeviceWeight> apply, see above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOWriteBandwidthMax',
      {
        'description' => 'Set the per-device overall block I/O bandwidth maximum limit for the executed processes, if the unified
control group hierarchy is used on the system. This limit is not work-conserving and the executed processes
are not allowed to use more even if the device has idle capacity.  Takes a space-separated pair of a file
path and a bandwidth value (in bytes per second) to specify the device specific bandwidth. The file path may
be a path to a block device node, or as any other file in which case the backing block device of the file
system of the file is used. If the bandwidth is suffixed with K, M, G, or T, the specified bandwidth is
parsed as Kilobytes, Megabytes, Gigabytes, or Terabytes, respectively, to the base of 1000. (Example:
"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 5M"). This controls the C<io.max> control
group attributes. Use this option multiple times to set bandwidth limits for multiple devices. For details
about this control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

Similar restrictions on block device discovery as for C<IODeviceWeight> apply, see above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOReadIOPSMax',
      {
        'description' => 'Set the per-device overall block I/O IOs-Per-Second maximum limit for the executed processes, if the
unified control group hierarchy is used on the system. This limit is not work-conserving and the executed
processes are not allowed to use more even if the device has idle capacity.  Takes a space-separated pair of
a file path and an IOPS value to specify the device specific IOPS. The file path may be a path to a block
device node, or as any other file in which case the backing block device of the file system of the file is
used. If the IOPS is suffixed with K, M, G, or T, the specified IOPS is parsed as KiloIOPS, MegaIOPS,
GigaIOPS, or TeraIOPS, respectively, to the base of 1000. (Example:
"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 1K"). This controls the C<io.max> control
group attributes. Use this option multiple times to set IOPS limits for multiple devices. For details about
this control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

Similar restrictions on block device discovery as for C<IODeviceWeight> apply, see above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IOWriteIOPSMax',
      {
        'description' => 'Set the per-device overall block I/O IOs-Per-Second maximum limit for the executed processes, if the
unified control group hierarchy is used on the system. This limit is not work-conserving and the executed
processes are not allowed to use more even if the device has idle capacity.  Takes a space-separated pair of
a file path and an IOPS value to specify the device specific IOPS. The file path may be a path to a block
device node, or as any other file in which case the backing block device of the file system of the file is
used. If the IOPS is suffixed with K, M, G, or T, the specified IOPS is parsed as KiloIOPS, MegaIOPS,
GigaIOPS, or TeraIOPS, respectively, to the base of 1000. (Example:
"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 1K"). This controls the C<io.max> control
group attributes. Use this option multiple times to set IOPS limits for multiple devices. For details about
this control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

Similar restrictions on block device discovery as for C<IODeviceWeight> apply, see above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IODeviceLatencyTargetSec',
      {
        'description' => 'Set the per-device average target I/O latency for the executed processes, if the unified control group
hierarchy is used on the system. Takes a file path and a timespan separated by a space to specify
the device specific latency target. (Example: "/dev/sda 25ms"). The file path may be specified
as path to a block device node or as any other file, in which case the backing block device of the file
system of the file is determined. This controls the C<io.latency> control group
attribute. Use this option multiple times to set latency target for multiple devices. For details about this
control group attribute, see L<IO Interface Files|https://docs.kernel.org/admin-guide/cgroup-v2.html#io-interface-files>.

Implies C<IOAccounting=yes>.

These settings are supported only if the unified control group hierarchy is used.

Similar restrictions on block device discovery as for C<IODeviceWeight> apply, see above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IPAccounting',
      {
        'description' => "Takes a boolean argument. If true, turns on IPv4 and IPv6 network traffic accounting for packets sent
or received by the unit. When this option is turned on, all IPv4 and IPv6 sockets created by any process of
the unit are accounted for.

When this option is used in socket units, it applies to all IPv4 and IPv6 sockets
associated with it (including both listening and connection sockets where this applies). Note that for
socket-activated services, this configuration setting and the accounting data of the service unit and the
socket unit are kept separate, and displayed separately. No propagation of the setting and the collected
statistics is done, in either direction. Moreover, any traffic sent or received on any of the socket unit's
sockets is accounted to the socket unit \x{2014} and never to the service unit it might have activated, even if the
socket is used by it.

The system default for this setting may be controlled with C<DefaultIPAccounting> in
L<systemd-system.conf(5)>.",
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'IPAddressAllow',
      {
        'description' => "Turn on network traffic filtering for IP packets sent and received over
C<AF_INET> and C<AF_INET6> sockets. Both directives take a
space separated list of IPv4 or IPv6 addresses, each optionally suffixed with an address prefix
length in bits after a C</> character. If the suffix is omitted, the address is
considered a host address, i.e. the filter covers the whole address (32 bits for IPv4, 128 bits for
IPv6).

The access lists configured with this option are applied to all sockets created by processes
of this unit (or in the case of socket units, associated with it). The lists are implicitly
combined with any lists configured for any of the parent slice units this unit might be a member
of. By default both access lists are empty. Both ingress and egress traffic is filtered by these
settings. In case of ingress traffic the source IP address is checked against these access lists,
in case of egress traffic the destination IP address is checked. The following rules are applied in
turn:

In order to implement an allow-listing IP firewall, it is recommended to use a
C<IPAddressDeny>C<any> setting on an upper-level slice unit
(such as the root slice C<-.slice> or the slice containing all system services
C<system.slice> \x{2013} see
L<systemd.special(7)>
for details on these slice units), plus individual per-service C<IPAddressAllow>
lines permitting network access to relevant services, and only them.

Note that for socket-activated services, the IP access list configured on the socket unit
applies to all sockets associated with it directly, but not to any sockets created by the
ultimately activated services for it. Conversely, the IP access list configured for the service is
not applied to any sockets passed into the service via socket activation. Thus, it is usually a
good idea to replicate the IP access lists on both the socket and the service unit. Nevertheless,
it may make sense to maintain one list more open and the other one more restricted, depending on
the usecase.

If these settings are used multiple times in the same unit the specified lists are combined. If an
empty string is assigned to these settings the specific access list is reset and all previous settings undone.

In place of explicit IPv4 or IPv6 address and prefix length specifications a small set of symbolic
names may be used. The following names are defined:

Note that these settings might not be supported on some systems (for example if eBPF control group
support is not enabled in the underlying kernel or container manager). These settings will have no effect in
that case. If compatibility with such systems is desired it is hence recommended to not exclusively rely on
them for IP security.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IPAddressDeny',
      {
        'description' => "Turn on network traffic filtering for IP packets sent and received over
C<AF_INET> and C<AF_INET6> sockets. Both directives take a
space separated list of IPv4 or IPv6 addresses, each optionally suffixed with an address prefix
length in bits after a C</> character. If the suffix is omitted, the address is
considered a host address, i.e. the filter covers the whole address (32 bits for IPv4, 128 bits for
IPv6).

The access lists configured with this option are applied to all sockets created by processes
of this unit (or in the case of socket units, associated with it). The lists are implicitly
combined with any lists configured for any of the parent slice units this unit might be a member
of. By default both access lists are empty. Both ingress and egress traffic is filtered by these
settings. In case of ingress traffic the source IP address is checked against these access lists,
in case of egress traffic the destination IP address is checked. The following rules are applied in
turn:

In order to implement an allow-listing IP firewall, it is recommended to use a
C<IPAddressDeny>C<any> setting on an upper-level slice unit
(such as the root slice C<-.slice> or the slice containing all system services
C<system.slice> \x{2013} see
L<systemd.special(7)>
for details on these slice units), plus individual per-service C<IPAddressAllow>
lines permitting network access to relevant services, and only them.

Note that for socket-activated services, the IP access list configured on the socket unit
applies to all sockets associated with it directly, but not to any sockets created by the
ultimately activated services for it. Conversely, the IP access list configured for the service is
not applied to any sockets passed into the service via socket activation. Thus, it is usually a
good idea to replicate the IP access lists on both the socket and the service unit. Nevertheless,
it may make sense to maintain one list more open and the other one more restricted, depending on
the usecase.

If these settings are used multiple times in the same unit the specified lists are combined. If an
empty string is assigned to these settings the specific access list is reset and all previous settings undone.

In place of explicit IPv4 or IPv6 address and prefix length specifications a small set of symbolic
names may be used. The following names are defined:

Note that these settings might not be supported on some systems (for example if eBPF control group
support is not enabled in the underlying kernel or container manager). These settings will have no effect in
that case. If compatibility with such systems is desired it is hence recommended to not exclusively rely on
them for IP security.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IPIngressFilterPath',
      {
        'description' => 'Add custom network traffic filters implemented as BPF programs, applying to all IP packets
sent and received over C<AF_INET> and C<AF_INET6> sockets.
Takes an absolute path to a pinned BPF program in the BPF virtual filesystem (C</sys/fs/bpf/>).

The filters configured with this option are applied to all sockets created by processes
of this unit (or in the case of socket units, associated with it). The filters are loaded in addition
to filters any of the parent slice units this unit might be a member of as well as any
C<IPAddressAllow> and C<IPAddressDeny> filters in any of these units.
By default there are no filters specified.

If these settings are used multiple times in the same unit all the specified programs are attached. If an
empty string is assigned to these settings the program list is reset and all previous specified programs ignored.

If the path BPF_FS_PROGRAM_PATH in C<IPIngressFilterPath> assignment
is already being handled by C<BPFProgram> ingress hook, e.g.
C<BPFProgram>C<ingress>:BPF_FS_PROGRAM_PATH,
the assignment will be still considered valid and the program will be attached to a cgroup. Same for
C<IPEgressFilterPath> path and C<egress> hook.

Note that for socket-activated services, the IP filter programs configured on the socket unit apply to
all sockets associated with it directly, but not to any sockets created by the ultimately activated services
for it. Conversely, the IP filter programs configured for the service are not applied to any sockets passed into
the service via socket activation. Thus, it is usually a good idea, to replicate the IP filter programs on both
the socket and the service unit, however it often makes sense to maintain one configuration more open and the other
one more restricted, depending on the usecase.

Note that these settings might not be supported on some systems (for example if eBPF control group
support is not enabled in the underlying kernel or container manager). These settings will fail the service in
that case. If compatibility with such systems is desired it is hence recommended to attach your filter manually
(requires C<Delegate>C<yes>) instead of using this setting.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IPEgressFilterPath',
      {
        'description' => 'Add custom network traffic filters implemented as BPF programs, applying to all IP packets
sent and received over C<AF_INET> and C<AF_INET6> sockets.
Takes an absolute path to a pinned BPF program in the BPF virtual filesystem (C</sys/fs/bpf/>).

The filters configured with this option are applied to all sockets created by processes
of this unit (or in the case of socket units, associated with it). The filters are loaded in addition
to filters any of the parent slice units this unit might be a member of as well as any
C<IPAddressAllow> and C<IPAddressDeny> filters in any of these units.
By default there are no filters specified.

If these settings are used multiple times in the same unit all the specified programs are attached. If an
empty string is assigned to these settings the program list is reset and all previous specified programs ignored.

If the path BPF_FS_PROGRAM_PATH in C<IPIngressFilterPath> assignment
is already being handled by C<BPFProgram> ingress hook, e.g.
C<BPFProgram>C<ingress>:BPF_FS_PROGRAM_PATH,
the assignment will be still considered valid and the program will be attached to a cgroup. Same for
C<IPEgressFilterPath> path and C<egress> hook.

Note that for socket-activated services, the IP filter programs configured on the socket unit apply to
all sockets associated with it directly, but not to any sockets created by the ultimately activated services
for it. Conversely, the IP filter programs configured for the service are not applied to any sockets passed into
the service via socket activation. Thus, it is usually a good idea, to replicate the IP filter programs on both
the socket and the service unit, however it often makes sense to maintain one configuration more open and the other
one more restricted, depending on the usecase.

Note that these settings might not be supported on some systems (for example if eBPF control group
support is not enabled in the underlying kernel or container manager). These settings will fail the service in
that case. If compatibility with such systems is desired it is hence recommended to attach your filter manually
(requires C<Delegate>C<yes>) instead of using this setting.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SocketBindAllow',
      {
        'description' => "Allow or deny binding a socket address to a socket by matching it with the bind-rule and
applying a corresponding action if there is a match.

bind-rule describes socket properties such as address-family,
transport-protocol and ip-ports.

bind-rule :=
{ [address-familyC<:>][transport-protocolC<:>][ip-ports] | C<any> }

address-family := { C<ipv4> | C<ipv6> }

transport-protocol := { C<tcp> | C<udp> }

ip-ports := { ip-port | ip-port-range }

An optional address-family expects C<ipv4> or C<ipv6> values.
If not specified, a rule will be matched for both IPv4 and IPv6 addresses and applied depending on other socket fields, e.g. transport-protocol,
ip-port.

An optional transport-protocol expects C<tcp> or C<udp> transport protocol names.
If not specified, a rule will be matched for any transport protocol.

An optional ip-port value must lie within 1\x{2026}65535 interval inclusively, i.e.
dynamic port C<0> is not allowed. A range of sequential ports is described by
ip-port-range := ip-port-lowC<->ip-port-high,
where ip-port-low is smaller than or equal to ip-port-high
and both are within 1\x{2026}65535 inclusively.

A special value C<any> can be used to apply a rule to any address family, transport protocol and any port with a positive value.

To allow multiple rules assign C<SocketBindAllow> or C<SocketBindDeny> multiple times.
To clear the existing assignments pass an empty C<SocketBindAllow> or C<SocketBindDeny>
assignment.

For each of C<SocketBindAllow> and C<SocketBindDeny>, maximum allowed number of assignments is
C<128>.

The feature is implemented with C<cgroup/bind4> and C<cgroup/bind6> cgroup-bpf hooks.

Examples:
    \x{2026}
    # Allow binding IPv6 socket addresses with a port greater than or equal to 10000.
    [Service]
    SocketBindAllow=ipv6:10000-65535
    SocketBindDeny=any
    \x{2026}
    # Allow binding IPv4 and IPv6 socket addresses with 1234 and 4321 ports.
    [Service]
    SocketBindAllow=1234
    SocketBindAllow=4321
    SocketBindDeny=any
    \x{2026}
    # Deny binding IPv6 socket addresses.
    [Service]
    SocketBindDeny=ipv6
    \x{2026}
    # Deny binding IPv4 and IPv6 socket addresses.
    [Service]
    SocketBindDeny=any
    \x{2026}
    # Allow binding only over TCP
    [Service]
    SocketBindAllow=tcp
    SocketBindDeny=any
    \x{2026}
    # Allow binding only over IPv6/TCP
    [Service]
    SocketBindAllow=ipv6:tcp
    SocketBindDeny=any
    \x{2026}
    # Allow binding ports within 10000-65535 range over IPv4/UDP.
    [Service]
    SocketBindAllow=ipv4:udp:10000-65535
    SocketBindDeny=any
    \x{2026}
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SocketBindDeny',
      {
        'description' => "Allow or deny binding a socket address to a socket by matching it with the bind-rule and
applying a corresponding action if there is a match.

bind-rule describes socket properties such as address-family,
transport-protocol and ip-ports.

bind-rule :=
{ [address-familyC<:>][transport-protocolC<:>][ip-ports] | C<any> }

address-family := { C<ipv4> | C<ipv6> }

transport-protocol := { C<tcp> | C<udp> }

ip-ports := { ip-port | ip-port-range }

An optional address-family expects C<ipv4> or C<ipv6> values.
If not specified, a rule will be matched for both IPv4 and IPv6 addresses and applied depending on other socket fields, e.g. transport-protocol,
ip-port.

An optional transport-protocol expects C<tcp> or C<udp> transport protocol names.
If not specified, a rule will be matched for any transport protocol.

An optional ip-port value must lie within 1\x{2026}65535 interval inclusively, i.e.
dynamic port C<0> is not allowed. A range of sequential ports is described by
ip-port-range := ip-port-lowC<->ip-port-high,
where ip-port-low is smaller than or equal to ip-port-high
and both are within 1\x{2026}65535 inclusively.

A special value C<any> can be used to apply a rule to any address family, transport protocol and any port with a positive value.

To allow multiple rules assign C<SocketBindAllow> or C<SocketBindDeny> multiple times.
To clear the existing assignments pass an empty C<SocketBindAllow> or C<SocketBindDeny>
assignment.

For each of C<SocketBindAllow> and C<SocketBindDeny>, maximum allowed number of assignments is
C<128>.

The feature is implemented with C<cgroup/bind4> and C<cgroup/bind6> cgroup-bpf hooks.

Examples:
    \x{2026}
    # Allow binding IPv6 socket addresses with a port greater than or equal to 10000.
    [Service]
    SocketBindAllow=ipv6:10000-65535
    SocketBindDeny=any
    \x{2026}
    # Allow binding IPv4 and IPv6 socket addresses with 1234 and 4321 ports.
    [Service]
    SocketBindAllow=1234
    SocketBindAllow=4321
    SocketBindDeny=any
    \x{2026}
    # Deny binding IPv6 socket addresses.
    [Service]
    SocketBindDeny=ipv6
    \x{2026}
    # Deny binding IPv4 and IPv6 socket addresses.
    [Service]
    SocketBindDeny=any
    \x{2026}
    # Allow binding only over TCP
    [Service]
    SocketBindAllow=tcp
    SocketBindDeny=any
    \x{2026}
    # Allow binding only over IPv6/TCP
    [Service]
    SocketBindAllow=ipv6:tcp
    SocketBindDeny=any
    \x{2026}
    # Allow binding ports within 10000-65535 range over IPv4/UDP.
    [Service]
    SocketBindAllow=ipv4:udp:10000-65535
    SocketBindDeny=any
    \x{2026}
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestrictNetworkInterfaces',
      {
        'description' => 'Takes a list of space-separated network interface names. This option restricts the network
interfaces that processes of this unit can use. By default processes can only use the network interfaces
listed (allow-list). If the first character of the rule is C<~>, the effect is inverted:
the processes can only use network interfaces not listed (deny-list).

This option can appear multiple times, in which case the network interface names are merged. If the
empty string is assigned the set is reset, all prior assignments will have not effect.

If you specify both types of this option (i.e. allow-listing and deny-listing), the first encountered
will take precedence and will dictate the default action (allow vs deny). Then the next occurrences of this
option will add or delete the listed network interface names from the set, depending of its type and the
default action.

The loopback interface ("lo") is not treated in any special way, you have to configure it explicitly
in the unit file.

Example 1: allow-list


    RestrictNetworkInterfaces=eth1
    RestrictNetworkInterfaces=eth2

Programs in the unit will be only able to use the eth1 and eth2 network
interfaces.

Example 2: deny-list


    RestrictNetworkInterfaces=~eth1 eth2

Programs in the unit will be able to use any network interface but eth1 and eth2.

Example 3: mixed


    RestrictNetworkInterfaces=eth1 eth2
    RestrictNetworkInterfaces=~eth1

Programs in the unit will be only able to use the eth2 network interface.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DeviceAllow',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Control access to specific device nodes by the executed processes. Takes two space-separated
strings: a device node specifier followed by a combination of C<r>,
C<w>, C<m> to control reading,
writing, or creation of the specific device nodes by the unit
(mknod), respectively. This functionality is implemented using eBPF
filtering.

When access to all physical devices should be disallowed,
C<PrivateDevices> may be used instead. See
L<systemd.exec(5)>.

The device node specifier is either a path to a device node in the file system, starting with
C</dev/>, or a string starting with either C<char-> or
C<block-> followed by a device group name, as listed in
C</proc/devices>. The latter is useful to allow-list all current and future
devices belonging to a specific device group at once. The device group is matched according to
filename globbing rules, you may hence use the C<*> and C<?>
wildcards. (Note that such globbing wildcards are not available for device node path
specifications!) In order to match device nodes by numeric major/minor, use device node paths in
the C</dev/char/> and C</dev/block/> directories. However,
matching devices by major/minor is generally not recommended as assignments are neither stable nor
portable between systems or different kernel versions.

Examples: C</dev/sda5> is a path to a device node, referring to an ATA or
SCSI block device. C<char-pts> and C<char-alsa> are specifiers for
all pseudo TTYs and all ALSA sound devices, respectively. C<char-cpu/*> is a
specifier matching all CPU related device groups.

Note that allow lists defined this way should only reference device groups which are
resolvable at the time the unit is started. Any device groups not resolvable then are not added to
the device allow list. In order to work around this limitation, consider extending service units
with a pair of After=modprobe\@xyz.service and
Wants=modprobe\@xyz.service lines that load the necessary kernel module
implementing the device group if missing.
Example:
    \x{2026}
    [Unit]
    Wants=modprobe\@loop.service
    After=modprobe\@loop.service
    [Service]
    DeviceAllow=block-loop
    DeviceAllow=/dev/loop-control
    \x{2026}
",
        'type' => 'list'
      },
      'DevicePolicy',
      {
        'choice' => [
          'auto',
          'closed',
          'strict'
        ],
        'description' => '
Control the policy for allowing device access:
',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Slice',
      {
        'description' => 'The name of the slice unit to place the unit
in. Defaults to C<system.slice> for all
non-instantiated units of all unit types (except for slice
units themselves see below). Instance units are by default
placed in a subslice of C<system.slice>
that is named after the template name.

This option may be used to arrange systemd units in a
hierarchy of slices each of which might have resource
settings applied.

For units of type slice, the only accepted value for
this setting is the parent slice. Since the name of a slice
unit implies the parent slice, it is hence redundant to ever
set this parameter directly for slice units.

Special care should be taken when relying on the default slice assignment in templated service units
that have C<DefaultDependencies=no> set, see
L<systemd.service(5)>, section
"Default Dependencies" for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Delegate',
      {
        'description' => 'Turns on delegation of further resource control partitioning to processes of the unit. Units where this
is enabled may create and manage their own private subhierarchy of control groups below the control group of
the unit itself. For unprivileged services (i.e. those using the C<User> setting) the unit\'s
control group will be made accessible to the relevant user. When enabled the service manager will refrain
from manipulating control groups or moving processes below the unit\'s control group, so that a clear concept
of ownership is established: the control group tree above the unit\'s control group (i.e. towards the root
control group) is owned and managed by the service manager of the host, while the control group tree below
the unit\'s control group is owned and managed by the unit itself. Takes either a boolean argument or a list
of control group controller names. If true, delegation is turned on, and all supported controllers are
enabled for the unit, making them available to the unit\'s processes for management. If false, delegation is
turned off entirely (and no additional controllers are enabled). If set to a list of controllers, delegation
is turned on, and the specified controllers are enabled for the unit. Note that additional controllers than
the ones specified might be made available as well, depending on configuration of the containing slice unit
or other units contained in it. Note that assigning the empty string will enable delegation, but reset the
list of controllers, all assignments prior to this will have no effect.  Defaults to false.

Note that controller delegation to less privileged code is only safe on the unified control group
hierarchy. Accordingly, access to the specified controllers will not be granted to unprivileged services on
the legacy hierarchy, even when requested.

Not all of these controllers are available on all kernels however, and some are
specific to the unified hierarchy while others are specific to the legacy hierarchy. Also note that the
kernel might support further controllers, which aren\'t covered here yet as delegation is either not supported
at all for them or not defined cleanly.

For further details on the delegation model consult L<Control Group APIs and Delegation|https://systemd.io/CGROUP_DELEGATION>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DisableControllers',
      {
        'description' => 'Disables controllers from being enabled for a unit\'s children. If a controller listed is already in use
in its subtree, the controller will be removed from the subtree. This can be used to avoid child units being
able to implicitly or explicitly enable a controller. Defaults to not disabling any controllers.

It may not be possible to successfully disable a controller if the unit or any child of the unit in
question delegates controllers to its children, as any delegated subtree of the cgroup hierarchy is unmanaged
by systemd.

Multiple controllers may be specified, separated by spaces. You may also pass
C<DisableControllers> multiple times, in which case each new instance adds another controller
to disable. Passing C<DisableControllers> by itself with no controller name present resets
the disabled controller list.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ManagedOOMSwap',
      {
        'choice' => [
          'auto',
          'kill'
        ],
        'description' => 'Specifies how
L<systemd-oomd.service(8)>
will act on this unit\'s cgroups. Defaults to C<auto>.

When set to C<kill>, the unit becomes a candidate for monitoring by
systemd-oomd. If the cgroup passes the limits set by
L<oomd.conf(5)> or
the unit configuration, systemd-oomd will select a descendant cgroup and send
C<SIGKILL> to all of the processes under it. You can find more details on
candidates and kill behavior at
L<systemd-oomd.service(8)>
and
L<oomd.conf(5)>.

Setting either of these properties to C<kill> will also result in
C<After> and C<Wants> dependencies on
C<systemd-oomd.service> unless C<DefaultDependencies=no>.

When set to C<auto>, systemd-oomd will not actively use this
cgroup\'s data for monitoring and detection. However, if an ancestor cgroup has one of these
properties set to C<kill>, a unit with C<auto> can still be a candidate
for systemd-oomd to terminate.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ManagedOOMMemoryPressure',
      {
        'choice' => [
          'auto',
          'kill'
        ],
        'description' => 'Specifies how
L<systemd-oomd.service(8)>
will act on this unit\'s cgroups. Defaults to C<auto>.

When set to C<kill>, the unit becomes a candidate for monitoring by
systemd-oomd. If the cgroup passes the limits set by
L<oomd.conf(5)> or
the unit configuration, systemd-oomd will select a descendant cgroup and send
C<SIGKILL> to all of the processes under it. You can find more details on
candidates and kill behavior at
L<systemd-oomd.service(8)>
and
L<oomd.conf(5)>.

Setting either of these properties to C<kill> will also result in
C<After> and C<Wants> dependencies on
C<systemd-oomd.service> unless C<DefaultDependencies=no>.

When set to C<auto>, systemd-oomd will not actively use this
cgroup\'s data for monitoring and detection. However, if an ancestor cgroup has one of these
properties set to C<kill>, a unit with C<auto> can still be a candidate
for systemd-oomd to terminate.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ManagedOOMMemoryPressureLimit',
      {
        'description' => 'Overrides the default memory pressure limit set by
L<oomd.conf(5)> for
this unit (cgroup). Takes a percentage value between 0% and 100%, inclusive. This property is
ignored unless C<ManagedOOMMemoryPressure>C<kill>. Defaults to 0%,
which means to use the default set by
L<oomd.conf(5)>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ManagedOOMPreference',
      {
        'choice' => [
          'none',
          'avoid',
          'omit'
        ],
        'description' => 'Allows deprioritizing or omitting this unit\'s cgroup as a candidate when
systemd-oomd needs to act. Requires support for extended attributes (see
L<xattr(7)>)
in order to use C<avoid> or C<omit>.

When calculating candidates to relieve swap usage, systemd-oomd will
only respect these extended attributes if the unit\'s cgroup is owned by root.

When calculating candidates to relieve memory pressure, systemd-oomd
will only respect these extended attributes if the unit\'s cgroup owner, and the
owner of the monitored ancestor cgroup are the same. For example, if systemd-oomd
is calculating candidates for C<-.slice>, then extended attributes set
on descendants of C</user.slice/user-1000.slice/user@1000.service/>
will be ignored because the descendants are owned by UID 1000, and C<-.slice>
is owned by UID 0. But, if calculating candidates for
C</user.slice/user-1000.slice/user@1000.service/>, then extended attributes set
on the descendants would be respected.

If this property is set to C<avoid>, the service manager will convey this to
systemd-oomd, which will only select this cgroup if there are no other viable
candidates.

If this property is set to C<omit>, the service manager will convey this to
systemd-oomd, which will ignore this cgroup as a candidate and will not perform
any actions on it.

It is recommended to use C<avoid> and C<omit> sparingly, as it
can adversely affect systemd-oomd\'s kill behavior. Also note that these extended
attributes are not applied recursively to cgroups under this unit\'s cgroup.

Defaults to C<none> which means systemd-oomd will rank this
unit\'s cgroup as defined in
L<systemd-oomd.service(8)>
and L<oomd.conf(5)>.
',
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd 252 doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Common::ResourceControl'
  }
]
;


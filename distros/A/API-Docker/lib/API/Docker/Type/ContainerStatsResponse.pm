package API::Docker::Type::ContainerStatsResponse;
# ABSTRACT: Statistics sample for a container
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerBlkioStats;
use API::Docker::Type::ContainerCPUStats;
use API::Docker::Type::ContainerMemoryStats;
use API::Docker::Type::ContainerNetworkStats;
use API::Docker::Type::ContainerPidsStats;
use API::Docker::Type::ContainerStorageStats;
use namespace::clean;


docker name => Str, wire => 'name', since => '1.51';


docker id => Str, wire => 'id', since => '1.51';


docker read => Str, wire => 'read', since => '1.51';


docker preread => Str, wire => 'preread', since => '1.51';


docker pids_stats => 'ContainerPidsStats',
  wire => 'pids_stats', since => '1.51';


docker blkio_stats => 'ContainerBlkioStats',
  wire => 'blkio_stats', since => '1.51';


docker num_procs => Int, wire => 'num_procs', since => '1.51';


docker storage_stats => 'ContainerStorageStats',
  wire => 'storage_stats', since => '1.51';


docker cpu_stats => 'ContainerCPUStats', wire => 'cpu_stats', since => '1.51';


docker precpu_stats => 'ContainerCPUStats',
  wire => 'precpu_stats', since => '1.51';


docker memory_stats => 'ContainerMemoryStats',
  wire => 'memory_stats', since => '1.51';


docker networks => { Str, 'ContainerNetworkStats' },
  wire => 'networks', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerStatsResponse - Statistics sample for a container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerStatsResponse> definition of
C<spec/v1.51.yaml>.

=head2 name

Name of the container. Serialised as C<name> -- spelled out, because
deriving it from the Perl name would produce C<Name>.

=head2 id

ID of the container. Serialised as C<id> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=head2 read

Date and time at which this sample was collected. The value is formatted as
L<RFC 3339|https://www.ietf.org/rfc/rfc3339.txt> with nano-seconds.
Serialised as C<read> -- spelled out, because deriving it from the Perl name
would produce C<Read>.

=head2 preread

Date and time at which this first sample was collected. This field is not
propagated if the "one-shot" option is set. If the "one-shot" option is set,
this field may be omitted, empty, or set to a default date
(C<0001-01-01T00:00:00Z>).

The value is formatted as L<RFC 3339|https://www.ietf.org/rfc/rfc3339.txt>
with nano-seconds. Serialised as C<preread> -- spelled out, because deriving
it from the Perl name would produce C<Preread>.

=head2 pids_stats

PidsStats contains Linux-specific stats of a container's process-IDs (PIDs).
See L<API::Docker::Type::ContainerPidsStats>. Serialised as C<pids_stats> --
spelled out, because deriving it from the Perl name would produce
C<PidsStats>.

=head2 blkio_stats

BlkioStats stores all IO service stats for data read and write. See
L<API::Docker::Type::ContainerBlkioStats>. Serialised as C<blkio_stats> --
spelled out, because deriving it from the Perl name would produce
C<BlkioStats>.

=head2 num_procs

The number of processors on the system.

This field is Windows-specific and always zero for Linux containers.
Serialised as C<num_procs> -- spelled out, because deriving it from the Perl
name would produce C<NumProcs>.

=head2 storage_stats

StorageStats is the disk I/O stats for read/write on Windows. See
L<API::Docker::Type::ContainerStorageStats>. Serialised as C<storage_stats>
-- spelled out, because deriving it from the Perl name would produce
C<StorageStats>.

=head2 cpu_stats

CPU related info of the container. See
L<API::Docker::Type::ContainerCPUStats>. Serialised as C<cpu_stats> --
spelled out, because deriving it from the Perl name would produce
C<CpuStats>.

=head2 precpu_stats

CPU related info of the container. See
L<API::Docker::Type::ContainerCPUStats>. Serialised as C<precpu_stats> --
spelled out, because deriving it from the Perl name would produce
C<PrecpuStats>.

=head2 memory_stats

Aggregates all memory stats since container inception on Linux. See
L<API::Docker::Type::ContainerMemoryStats>. Serialised as C<memory_stats> --
spelled out, because deriving it from the Perl name would produce
C<MemoryStats>.

=head2 networks

Network statistics for the container per interface.

This field is omitted if the container has no networking enabled. See
L<API::Docker::Type::ContainerNetworkStats>. B<The keys are the caller's
data> and are never translated. Serialised as C<networks> -- spelled out,
because deriving it from the Perl name would produce C<Networks>.

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

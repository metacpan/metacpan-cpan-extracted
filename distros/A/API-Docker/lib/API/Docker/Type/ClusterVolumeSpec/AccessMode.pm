package API::Docker::Type::ClusterVolumeSpec::AccessMode;
# ABSTRACT: Defines how the volume is used by tasks
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterVolumeSpec::AccessMode::AccessibilityRequirements;
use API::Docker::Type::ClusterVolumeSpec::AccessMode::CapacityRange;
use API::Docker::Type::ClusterVolumeSpec::AccessMode::Secret;
use namespace::clean;


docker scope => Str, since => '1.44', enum => [qw( single multi )];


docker sharing => Str,
  since => '1.44', enum => [qw( none readonly onewriter all )];


docker mount_volume => Any, since => '1.44';


docker secrets => [ 'ClusterVolumeSpec::AccessMode::Secret' ],
  since => '1.44';


docker accessibility_requirements => 'ClusterVolumeSpec::AccessMode::AccessibilityRequirements',
  since => '1.44';


docker capacity_range => 'ClusterVolumeSpec::AccessMode::CapacityRange',
  since => '1.44';


docker availability => Str,
  since => '1.44', enum => [qw( active pause drain )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolumeSpec::AccessMode - Defines how the volume is used by tasks

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<AccessMode> schema of the C<ClusterVolumeSpec>
definition in C<spec/v1.51.yaml>.

=head2 scope

The set of nodes this volume can be used on at one time.

=over 4

=item * C<single> The volume may only be scheduled to one node at a time.

=item * C<multi> the volume may be scheduled to any supported number of
nodes at a time.

=back

The daemon defaults it to single.

=head2 sharing

The number and way that different tasks can use this volume at one time.

=over 4

=item * C<none> The volume may only be used by one task at a time.

=item * C<readonly> The volume may be used by any number of tasks, but they
all must mount the volume as readonly

=item * C<onewriter> The volume may be used by any number of tasks, but only
one may mount it as read/write.

=item * C<all> The volume may have any number of readers and writers.

=back

The daemon defaults it to none.

=head2 mount_volume

Options for using this volume as a Mount-type volume.

Either MountVolume or BlockVolume, but not both, must be present.
properties: FsType: type: "string" description: | Specifies the filesystem
type for the mount volume. Optional. MountFlags: type: "array" description:
| Flags to pass when mounting the volume. Optional. items: type: "string"
BlockVolume: type: "object" description: | Options for using this volume as
a Block-type volume. Intentionally empty.

=head2 secrets

Swarm Secrets that are passed to the CSI storage plugin when operating on
this volume. See
L<API::Docker::Type::ClusterVolumeSpec::AccessMode::Secret>.

=head2 accessibility_requirements

Requirements for the accessible topology of the volume. These fields are
optional. For an in-depth description of what these fields mean, see the CSI
specification. See
L<API::Docker::Type::ClusterVolumeSpec::AccessMode::AccessibilityRequirements>.

=head2 capacity_range

The desired capacity that the volume should be created with. If empty, the
plugin will decide the capacity. See
L<API::Docker::Type::ClusterVolumeSpec::AccessMode::CapacityRange>.

=head2 availability

The availability of the volume for use in tasks.

=over 4

=item * C<active> The volume is fully available for scheduling on the
cluster

=item * C<pause> No new workloads should use the volume, but existing
workloads are not stopped.

=item * C<drain> All workloads using this volume should be stopped and
rescheduled, and no new ones should be started.

=back

The daemon defaults it to active.

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

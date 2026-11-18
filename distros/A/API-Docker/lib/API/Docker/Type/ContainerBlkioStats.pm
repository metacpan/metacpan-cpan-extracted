package API::Docker::Type::ContainerBlkioStats;
# ABSTRACT: BlkioStats stores all IO service stats for data read and write
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerBlkioStatEntry;
use namespace::clean;


docker io_service_bytes_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_service_bytes_recursive', since => '1.51';


docker io_serviced_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_serviced_recursive', since => '1.51';


docker io_queue_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_queue_recursive', since => '1.51';


docker io_service_time_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_service_time_recursive', since => '1.51';


docker io_wait_time_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_wait_time_recursive', since => '1.51';


docker io_merged_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_merged_recursive', since => '1.51';


docker io_time_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'io_time_recursive', since => '1.51';


docker sectors_recursive => [ 'ContainerBlkioStatEntry' ],
  wire => 'sectors_recursive', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerBlkioStats - BlkioStats stores all IO service stats for data read and write

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerBlkioStats> definition of C<spec/v1.51.yaml>.

This type is Linux-specific and holds many fields that are specific to
cgroups v1. On a cgroup v2 host, all fields other than
C<io_service_bytes_recursive> are omitted or C<null>.

This type is only populated on Linux and omitted for Windows containers.

=head2 io_service_bytes_recursive

Undocumented upstream. Bytes transferred, one entry per device and
operation. It is the only one of the eight arrays a cgroup v2 host fills in,
which is also why it is the only one carrying no description: the other
seven each say they are cgroup v1 only, and this one had nothing left to
qualify. See L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_service_bytes_recursive> -- spelled out, because deriving it from the
Perl name would produce C<IoServiceBytesRecursive>.

=head2 io_serviced_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_serviced_recursive> -- spelled out, because deriving it from the Perl
name would produce C<IoServicedRecursive>.

=head2 io_queue_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_queue_recursive> -- spelled out, because deriving it from the Perl name
would produce C<IoQueueRecursive>.

=head2 io_service_time_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_service_time_recursive> -- spelled out, because deriving it from the
Perl name would produce C<IoServiceTimeRecursive>.

=head2 io_wait_time_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_wait_time_recursive> -- spelled out, because deriving it from the Perl
name would produce C<IoWaitTimeRecursive>.

=head2 io_merged_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_merged_recursive> -- spelled out, because deriving it from the Perl
name would produce C<IoMergedRecursive>.

=head2 io_time_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<io_time_recursive> -- spelled out, because deriving it from the Perl name
would produce C<IoTimeRecursive>.

=head2 sectors_recursive

This field is only available when using Linux containers with cgroups v1. It
is omitted or C<null> when using cgroups v2. See
L<API::Docker::Type::ContainerBlkioStatEntry>. Serialised as
C<sectors_recursive> -- spelled out, because deriving it from the Perl name
would produce C<SectorsRecursive>.

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

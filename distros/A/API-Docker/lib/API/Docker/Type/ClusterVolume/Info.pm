package API::Docker::Type::ClusterVolume::Info;
# ABSTRACT: Information about the global status of the volume
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Topology;
use namespace::clean;


docker capacity_bytes => Int, since => '1.44';


docker volume_context => { Str, Str }, since => '1.44';


docker volume_id => Str, wire => 'VolumeID', since => '1.44';


docker accessible_topology => [ 'Topology' ], since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolume::Info - Information about the global status of the volume

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Info> schema of the C<ClusterVolume> definition
in C<spec/v1.51.yaml>.

=head2 capacity_bytes

The capacity of the volume in bytes. A value of 0 indicates that the
capacity is unknown.

=head2 volume_context

A map of strings to strings returned from the storage plugin when the volume
is created. B<The keys are the caller's data> and are never translated.

=head2 volume_id

The ID of the volume as returned by the CSI storage plugin. This is distinct
from the volume's ID as provided by Docker. This ID is never used by the
user when communicating with Docker to refer to this volume. If the ID is
blank, then the Volume has not been successfully created in the plugin yet.
Serialised as C<VolumeID> -- spelled out, because deriving it from the Perl
name would produce C<VolumeId>.

=head2 accessible_topology

The topology this volume is actually accessible from. See
L<API::Docker::Type::Topology>.

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

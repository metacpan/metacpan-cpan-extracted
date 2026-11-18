package API::Docker::Type::ClusterVolume;
# ABSTRACT: Options and information specific to, and only present on, Swarm CSI cluster volumes
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterVolume::Info;
use API::Docker::Type::ClusterVolume::PublishStatus;
use API::Docker::Type::ClusterVolumeSpec;
use API::Docker::Type::ObjectVersion;
use namespace::clean;


docker id => Str, wire => 'ID', since => '1.44';


docker version => 'ObjectVersion', since => '1.44';


docker created_at => Str, since => '1.44';


docker updated_at => Str, since => '1.44';


docker spec => 'ClusterVolumeSpec', since => '1.44';


docker info => 'ClusterVolume::Info', since => '1.44';


docker publish_status => [ 'ClusterVolume::PublishStatus' ], since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolume - Options and information specific to, and only present on, Swarm CSI cluster volumes

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ClusterVolume> definition of C<spec/v1.51.yaml>.

=head2 id

The Swarm ID of this volume. Because cluster volumes are Swarm objects, they
have an ID, unlike non-cluster volumes. This ID can be used to refer to the
Volume instead of the name. Serialised as C<ID> -- spelled out, because
deriving it from the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Undocumented upstream. A C<dateTime>, with no example given. Cluster volumes
are Swarm objects, which is what L</id> says makes them carry an ID where a
plain volume does not, and it is why they carry these two timestamps as
well.

=head2 updated_at

Undocumented upstream. The same, for the last change.

=head2 spec

Cluster-specific options used to create the volume. See
L<API::Docker::Type::ClusterVolumeSpec>.

=head2 info

Information about the global status of the volume. See
L<API::Docker::Type::ClusterVolume::Info>.

=head2 publish_status

The status of the volume as it pertains to its publishing and use on
specific nodes. See L<API::Docker::Type::ClusterVolume::PublishStatus>.

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

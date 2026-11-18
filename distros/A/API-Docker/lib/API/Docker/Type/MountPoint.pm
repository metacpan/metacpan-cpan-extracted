package API::Docker::Type::MountPoint;
# ABSTRACT: A mount point configuration inside the container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker type => Str, enum => [qw( bind cluster image npipe tmpfs volume )];


docker name => Str;


docker source => Str;


docker destination => Str;


docker driver => Str;


docker mode => Str;


docker rw => Bool, wire => 'RW';


docker propagation => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::MountPoint - A mount point configuration inside the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<MountPoint> definition of C<spec/v1.51.yaml>.

This is used for reporting the mountpoints in use by a container.

=head2 type

The mount type:

=over 4

=item * C<bind> a mount of a file or directory from the host into the
container.

=item * C<cluster> a Swarm cluster volume.

=item * C<image> an OCI image.

=item * C<npipe> a named pipe from the host into the container.

=item * C<tmpfs> a C<tmpfs>.

=item * C<volume> a docker volume with the given C<Name>.

=back

The swagger types this field as an C<allOf> around a single C<$ref> to
C<MountType>, which is a string and not an object, so it is a plain Str
here.

=head2 name

Name is the name reference to the underlying data defined by C<Source> e.g.,
the volume name.

=head2 source

Source location of the mount.

For volumes, this contains the storage location of the volume (within
C</var/lib/docker/volumes/>). For bind-mounts, and C<npipe>, this contains
the source (host) part of the bind-mount. For C<tmpfs> mount points, this
field is empty.

=head2 destination

Destination is the path relative to the container root (C</>) where the
C<Source> is mounted inside the container.

=head2 driver

Driver is the volume driver used to create the volume (if it is a volume).

=head2 mode

Mode is a comma separated list of options supplied by the user when creating
the bind/volume mount.

The default is platform-specific (C<"z"> on Linux, empty on Windows).

=head2 rw

Whether the mount is mounted writable (read-write). Serialised as C<RW> --
spelled out, because deriving it from the Perl name would produce C<Rw>.

=head2 propagation

Propagation describes how mounts are propagated from the host into the mount
point, and vice-versa. Refer to the L<Linux kernel
documentation|https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt>
for details. This field is not used on Windows.

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

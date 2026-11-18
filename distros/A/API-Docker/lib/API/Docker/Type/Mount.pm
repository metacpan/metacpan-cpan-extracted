package API::Docker::Type::Mount;
# ABSTRACT: One entry of a container's Mounts specification
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Mount::BindOptions;
use API::Docker::Type::Mount::ImageOptions;
use API::Docker::Type::Mount::TmpfsOptions;
use API::Docker::Type::Mount::VolumeOptions;
use namespace::clean;


docker target => Str;


docker source => Str;


docker type => Str, enum => [qw( bind cluster image npipe tmpfs volume )];


docker read_only => Bool;


docker consistency => Str;


docker bind_options => 'Mount::BindOptions';


docker volume_options => 'Mount::VolumeOptions';


docker image_options => 'Mount::ImageOptions', since => '1.51';


docker tmpfs_options => 'Mount::TmpfsOptions';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Mount - One entry of a container's Mounts specification

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Mount> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<HostConfig.Mounts> and C<TaskSpec.ContainerSpec.Mounts>.

The four C<*Options> fields are objects the swagger writes inline rather
than referencing, so each becomes a class named after this one:
L<API::Docker::Type::Mount::BindOptions>,
L<API::Docker::Type::Mount::VolumeOptions>,
L<API::Docker::Type::Mount::ImageOptions> and
L<API::Docker::Type::Mount::TmpfsOptions>.

=head2 target

Container path.

=head2 source

Mount source (e.g. a volume name, a host path). The source cannot be
specified when using C<Type=tmpfs>. For C<Type=bind>, the source path must
either exist, or the C<CreateMountpoint> must be set to C<true> to create
the source path on the host if missing.

For C<Type=npipe>, the pipe must exist prior to creating the container.

=head2 type

The mount type. Available types:

=over 4

=item * C<bind> Mounts a file or directory from the host into the container.
The C<Source> must exist prior to creating the container.

=item * C<cluster> a Swarm cluster volume

=item * C<image> Mounts an image.

=item * C<npipe> Mounts a named pipe from the host into the container. The
C<Source> must exist prior to creating the container.

=item * C<tmpfs> Create a tmpfs with the given options. The mount C<Source>
cannot be specified for tmpfs.

=item * C<volume> Creates a volume with the given name and options (or uses
a pre-existing volume with the same name and options). These are B<not>
removed when the container is removed.

=back

The swagger types this field as an C<allOf> around a single C<$ref> to
C<MountType>, which is a string and not an object, so it is a plain Str
here.

=head2 read_only

Whether the mount should be read-only.

=head2 consistency

The consistency requirement for the mount: C<default>, C<consistent>,
C<cached>, or C<delegated>.

=head2 bind_options

Optional configuration for the C<bind> type. See
L<API::Docker::Type::Mount::BindOptions>.

=head2 volume_options

Optional configuration for the C<volume> type. See
L<API::Docker::Type::Mount::VolumeOptions>.

=head2 image_options

Optional configuration for the C<image> type. See
L<API::Docker::Type::Mount::ImageOptions>.

=head2 tmpfs_options

Optional configuration for the C<tmpfs> type. See
L<API::Docker::Type::Mount::TmpfsOptions>.

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

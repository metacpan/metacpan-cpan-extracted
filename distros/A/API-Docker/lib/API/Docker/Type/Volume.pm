package API::Docker::Type::Volume;
# ABSTRACT: The body of the C<200> response to C<GET /volumes/{name}>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterVolume;
use API::Docker::Type::Volume::UsageData;
use namespace::clean;


docker name => Str, required => 1;


docker driver => Str, required => 1;


docker mountpoint => Str, required => 1;


docker created_at => Str;


docker status => { Str, Any };


docker labels => { Str, Str }, required => 1;


docker scope => Str, required => 1, enum => [qw( local global )];


docker cluster_volume => 'ClusterVolume', since => '1.44';


docker options => { Str, Str }, required => 1;


docker usage_data => 'Volume::UsageData';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Volume - The body of the C<200> response to C<GET /volumes/{name}>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Volume> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of the
C<200> response to C<GET /volumes/{name}>, the body of the C<201> response
to C<POST /volumes/create> and one entry of the C<Volumes> field of the
C<200> response to C<GET /system/df>.

=head2 name

Name of the volume. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 driver

Name of the volume driver used by the volume. The swagger lists this field
as required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 mountpoint

Mount path of the volume on the host. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 created_at

Date/Time the volume was created.

=head2 status

Low-level details about the volume, provided by the volume driver. Details
are returned as a map with key/value pairs:
C<{"key":"value","key2":"value2"}>.

The C<Status> field is optional, and is omitted if the volume driver does
not support this feature. B<The keys are the caller's data> and are never
translated.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 scope

The level at which the volume exists. Either C<global> for cluster-wide, or
C<local> for machine level. The daemon defaults it to local. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 cluster_volume

Options and information specific to, and only present on, Swarm CSI cluster
volumes. See L<API::Docker::Type::ClusterVolume>.

=head2 options

The driver specific options used when creating the volume. B<The keys are
the caller's data> and are never translated. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 usage_data

Usage details about the volume. This information is used by the C<GET
/system/df> endpoint, and omitted in other endpoints. See
L<API::Docker::Type::Volume::UsageData>.

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

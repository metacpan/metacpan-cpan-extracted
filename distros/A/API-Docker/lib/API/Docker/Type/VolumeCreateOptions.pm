package API::Docker::Type::VolumeCreateOptions;
# ABSTRACT: Volume configuration
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterVolumeSpec;
use namespace::clean;


docker name => Str;


docker driver => Str;


docker driver_opts => { Str, Str };


docker labels => { Str, Str };


docker cluster_volume_spec => 'ClusterVolumeSpec', since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::VolumeCreateOptions - Volume configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<VolumeCreateOptions> definition of C<spec/v1.51.yaml>.

=head2 name

The new volume's name. If not specified, Docker generates a name.

=head2 driver

Name of the volume driver to use. The daemon defaults it to local.

=head2 driver_opts

A mapping of driver options and values. These options are passed directly to
the driver and are driver specific. B<The keys are the caller's data> and
are never translated.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 cluster_volume_spec

Cluster-specific options used to create the volume. See
L<API::Docker::Type::ClusterVolumeSpec>.

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

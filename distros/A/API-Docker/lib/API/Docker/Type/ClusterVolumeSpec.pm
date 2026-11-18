package API::Docker::Type::ClusterVolumeSpec;
# ABSTRACT: Cluster-specific options used to create the volume
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterVolumeSpec::AccessMode;
use namespace::clean;


docker group => Str, since => '1.44';


docker access_mode => 'ClusterVolumeSpec::AccessMode', since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolumeSpec - Cluster-specific options used to create the volume

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ClusterVolumeSpec> definition of C<spec/v1.51.yaml>.

=head2 group

Group defines the volume group of this volume. Volumes belonging to the same
group can be referred to by group name when creating Services. Referring to
a volume by group instructs Swarm to treat volumes in that group
interchangeably for the purpose of scheduling. Volumes with an empty string
for a group technically all belong to the same, emptystring group.

=head2 access_mode

Defines how the volume is used by tasks. See
L<API::Docker::Type::ClusterVolumeSpec::AccessMode>.

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

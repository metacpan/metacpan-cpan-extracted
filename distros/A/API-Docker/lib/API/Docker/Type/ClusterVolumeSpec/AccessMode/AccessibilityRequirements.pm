package API::Docker::Type::ClusterVolumeSpec::AccessMode::AccessibilityRequirements;
# ABSTRACT: Requirements for the accessible topology of the volume
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Topology;
use namespace::clean;


docker requisite => [ 'Topology' ], since => '1.44';


docker preferred => [ 'Topology' ], since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolumeSpec::AccessMode::AccessibilityRequirements - Requirements for the accessible topology of the volume

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<AccessibilityRequirements> schema of
C<ClusterVolumeSpec.AccessMode> in C<spec/v1.51.yaml>.

These fields are optional. For an in-depth description of what these fields
mean, see the CSI specification.

=head2 requisite

A list of required topologies, at least one of which the volume must be
accessible from. See L<API::Docker::Type::Topology>.

=head2 preferred

A list of topologies that the volume should attempt to be provisioned in.
See L<API::Docker::Type::Topology>.

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

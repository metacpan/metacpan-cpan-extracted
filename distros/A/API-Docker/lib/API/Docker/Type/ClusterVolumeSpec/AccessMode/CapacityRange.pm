package API::Docker::Type::ClusterVolumeSpec::AccessMode::CapacityRange;
# ABSTRACT: The desired capacity that the volume should be created with
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker required_bytes => Int, since => '1.44';


docker limit_bytes => Int, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolumeSpec::AccessMode::CapacityRange - The desired capacity that the volume should be created with

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<CapacityRange> schema of
C<ClusterVolumeSpec.AccessMode> in C<spec/v1.51.yaml>.

If empty, the plugin will decide the capacity.

=head2 required_bytes

The volume must be at least this big. The value of 0 indicates an
unspecified minimum.

=head2 limit_bytes

The volume must not be bigger than this. The value of 0 indicates an
unspecified maximum.

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

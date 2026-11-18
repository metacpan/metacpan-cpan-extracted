package API::Docker::Type::ImageManifestSummary::ImageData;
# ABSTRACT: The image data for the image manifest
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ImageManifestSummary::ImageData::Size;
use API::Docker::Type::OCIPlatform;
use namespace::clean;


docker platform => 'OCIPlatform', since => '1.51';


docker containers => [Str], since => '1.51';


docker size => 'ImageManifestSummary::ImageData::Size', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageManifestSummary::ImageData - The image data for the image manifest

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<ImageData> schema of the C<ImageManifestSummary>
definition in C<spec/v1.51.yaml>.

This field is only populated when Kind is "image".

=head2 platform

OCI platform of the image. This will be the platform specified in the
manifest descriptor from the index/manifest list. If it's not available, it
will be obtained from the image config. See
L<API::Docker::Type::OCIPlatform>.

=head2 containers

The IDs of the containers that are using this image.

=head2 size

Undocumented upstream. One byte count, C<Unpacked>: the unpacked,
uncompressed image content a container running this image uses. See
L<API::Docker::Type::ImageManifestSummary::ImageData::Size>.

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

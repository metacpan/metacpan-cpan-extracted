package API::Docker::Type::ImageManifestSummary;
# ABSTRACT: A summary of an image manifest
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ImageManifestSummary::AttestationData;
use API::Docker::Type::ImageManifestSummary::ImageData;
use API::Docker::Type::ImageManifestSummary::Size;
use API::Docker::Type::OCIDescriptor;
use namespace::clean;


docker id => Str, wire => 'ID', since => '1.51', required => 1;


docker descriptor => 'OCIDescriptor', since => '1.51', required => 1;


docker available => Bool, since => '1.51', required => 1;


docker size => 'ImageManifestSummary::Size', since => '1.51', required => 1;


docker kind => Str,
  since => '1.51', required => 1, enum => [qw( image attestation unknown )];


docker image_data => 'ImageManifestSummary::ImageData', since => '1.51';


docker attestation_data => 'ImageManifestSummary::AttestationData',
  since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageManifestSummary - A summary of an image manifest

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageManifestSummary> definition of C<spec/v1.51.yaml>.

=head2 id

ID is the content-addressable ID of an image and is the same as the digest
of the image manifest. Serialised as C<ID> -- spelled out, because deriving
it from the Perl name would produce C<Id>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 descriptor

A descriptor struct containing digest, media type, and size, as defined in
the L<OCI Content Descriptors
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>.
See L<API::Docker::Type::OCIDescriptor>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 available

Indicates whether all the child content (image config, layers) is fully
available locally. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 size

Undocumented upstream. Two byte counts: C<Content> for what of this manifest
and its children is in the local content store, C<Total> for that plus every
other locally present byte belonging to it. See
L<API::Docker::Type::ImageManifestSummary::Size>. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 kind

The kind of the manifest.

kind | description
-------------|-----------------------------------------------------------
image | Image manifest that can be used to start a container. attestation |
Attestation manifest produced by the Buildkit builder for a specific image
manifest. The swagger enumerates C<image>, C<attestation> and C<unknown>.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 image_data

The image data for the image manifest. This field is only populated when
Kind is "image". See L<API::Docker::Type::ImageManifestSummary::ImageData>.

=head2 attestation_data

The image data for the attestation manifest. This field is only populated
when Kind is "attestation". See
L<API::Docker::Type::ImageManifestSummary::AttestationData>.

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

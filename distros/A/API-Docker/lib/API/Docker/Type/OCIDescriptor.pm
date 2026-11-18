package API::Docker::Type::OCIDescriptor;
# ABSTRACT: A descriptor struct containing digest, media type, and size, as defined in the L<OCI Content Descriptors Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::OCIPlatform;
use namespace::clean;


docker media_type => Str, wire => 'mediaType';


docker digest => Str, wire => 'digest';


docker size => Int, wire => 'size';


docker urls => [Str], wire => 'urls', since => '1.51';


docker annotations => { Str, Str }, wire => 'annotations', since => '1.51';


docker data => Str, wire => 'data', since => '1.51';


docker platform => 'OCIPlatform', wire => 'platform', since => '1.51';


docker artifact_type => Str, wire => 'artifactType', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::OCIDescriptor - A descriptor struct containing digest, media type, and size, as defined in the L<OCI Content Descriptors Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<OCIDescriptor> definition of C<spec/v1.51.yaml>.

=head2 media_type

The media type of the object this schema refers to. Serialised as
C<mediaType> -- spelled out, because deriving it from the Perl name would
produce C<MediaType>.

=head2 digest

The digest of the targeted content. Serialised as C<digest> -- spelled out,
because deriving it from the Perl name would produce C<Digest>.

=head2 size

The size in bytes of the blob. Serialised as C<size> -- spelled out, because
deriving it from the Perl name would produce C<Size>.

=head2 urls

List of URLs from which this object MAY be downloaded. Serialised as C<urls>
-- spelled out, because deriving it from the Perl name would produce
C<Urls>.

=head2 annotations

Arbitrary metadata relating to the targeted content. B<The keys are the
caller's data> and are never translated. Serialised as C<annotations> --
spelled out, because deriving it from the Perl name would produce
C<Annotations>.

=head2 data

Data is an embedding of the targeted content. This is encoded as a base64
string when marshalled to JSON (automatically, by encoding/json). If
present, Data can be used directly to avoid fetching the targeted content.
Serialised as C<data> -- spelled out, because deriving it from the Perl name
would produce C<Data>.

=head2 platform

Describes the platform which the image in the manifest runs on, as defined
in the L<OCI Image Index
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/image-index.md>.
See L<API::Docker::Type::OCIPlatform>. Serialised as C<platform> -- spelled
out, because deriving it from the Perl name would produce C<Platform>.

=head2 artifact_type

ArtifactType is the IANA media type of this artifact. Serialised as
C<artifactType> -- spelled out, because deriving it from the Perl name would
produce C<ArtifactType>.

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

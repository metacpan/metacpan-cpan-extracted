package API::Docker::Type::ImageInspect;
# ABSTRACT: Information about an image in the local image cache
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::DriverData;
use API::Docker::Type::ImageConfig;
use API::Docker::Type::ImageInspect::Metadata;
use API::Docker::Type::ImageInspect::RootFS;
use API::Docker::Type::ImageManifestSummary;
use API::Docker::Type::OCIDescriptor;
use namespace::clean;


docker id => Str;


docker descriptor => 'OCIDescriptor', since => '1.51';


docker manifests => [ 'ImageManifestSummary' ], since => '1.51';


docker repo_tags => [Str];


docker repo_digests => [Str];


docker parent => Str;


docker comment => Str;


docker created => Str;


docker docker_version => Str;


docker author => Str;


docker config => 'ImageConfig';


docker architecture => Str;


docker variant => Str;


docker os => Str;


docker os_version => Str;


docker size => Int;


docker graph_driver => 'DriverData';


docker root_fs => 'ImageInspect::RootFS', wire => 'RootFS';


docker metadata => 'ImageInspect::Metadata';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageInspect - Information about an image in the local image cache

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageInspect> definition of C<spec/v1.51.yaml>.

=head2 id

ID is the content-addressable ID of an image.

This identifier is a content-addressable digest calculated from the image's
configuration (which includes the digests of layers used by the image).

Note that this digest differs from the C<RepoDigests> below, which holds
digests of image manifests that reference the image.

=head2 descriptor

Descriptor is an OCI descriptor of the image target. In case of a
multi-platform image, this descriptor points to the OCI index or a manifest
list.

This field is only present if the daemon provides a multi-platform image
store.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::OCIDescriptor>.

=head2 manifests

Manifests is a list of image manifests available in this image. It provides
a more detailed view of the platform-specific image manifests or other
image-attached data like build attestations.

Only available if the daemon provides a multi-platform image store and the
C<manifests> option is set in the inspect request.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::ImageManifestSummary>.

=head2 repo_tags

List of image names/tags in the local image cache that reference this image.

Multiple image tags can refer to the same image, and this list may be empty
if no tags reference the image, in which case the image is "untagged", in
which case it can still be referenced by its ID.

=head2 repo_digests

List of content-addressable digests of locally available image manifests
that the image is referenced from. Multiple manifests can refer to the same
image.

These digests are usually only available if the image was either pulled from
a registry, or if the image was pushed to a registry, which is when the
manifest is generated and its digest calculated.

=head2 parent

ID of the parent image.

Depending on how the image was created, this field may be empty and is only
set for images that were built/created locally. This field is empty if the
image was pulled from an image registry.

> B<Deprecated>: This field is only set when using the deprecated > legacy
builder. It is included in API responses for informational > purposes, but
should not be depended on as it will be omitted > once the legacy builder is
removed.

=head2 comment

Optional message that was set when committing or importing the image.

=head2 created

Date and time at which the image was created, formatted in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

This information is only available if present in the image, and omitted
otherwise.

=head2 docker_version

The version of Docker that was used to build the image.

Depending on how the image was created, this field may be empty.

> B<Deprecated>: This field is only set when using the deprecated > legacy
builder. It is included in API responses for informational > purposes, but
should not be depended on as it will be omitted > once the legacy builder is
removed.

=head2 author

Name of the author that was specified when committing the image, or as
specified through MAINTAINER (deprecated) in the Dockerfile.

=head2 config

Configuration of the image. See L<API::Docker::Type::ImageConfig>.

=head2 architecture

Hardware CPU architecture that the image runs on.

=head2 variant

CPU architecture variant (presently ARM-only).

=head2 os

Operating System the image is built to run on.

=head2 os_version

Operating System version the image is built to run on (especially for
Windows).

=head2 size

Total size of the image including all layers it is composed of.

=head2 graph_driver

Information about the storage driver used to store the container's and
image's filesystem. See L<API::Docker::Type::DriverData>.

=head2 root_fs

Information about the image's RootFS, including the layer IDs. See
L<API::Docker::Type::ImageInspect::RootFS>. Serialised as C<RootFS> --
spelled out, because deriving it from the Perl name would produce C<RootFs>.

=head2 metadata

Additional metadata of the image in the local cache. This information is
local to the daemon, and not part of the image itself. See
L<API::Docker::Type::ImageInspect::Metadata>.

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

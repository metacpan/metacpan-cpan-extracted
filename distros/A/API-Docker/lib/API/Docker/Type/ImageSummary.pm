package API::Docker::Type::ImageSummary;
# ABSTRACT: One entry of the C<200> response to C<GET /images/json>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ImageManifestSummary;
use API::Docker::Type::OCIDescriptor;
use namespace::clean;


docker id => Str, required => 1;


docker parent_id => Str, required => 1;


docker repo_tags => [Str], required => 1;


docker repo_digests => [Str], required => 1;


docker created => Int, required => 1;


docker size => Int, required => 1;


docker shared_size => Int, required => 1;


docker labels => { Str, Str }, required => 1;


docker containers => Int, required => 1;


docker manifests => [ 'ImageManifestSummary' ], since => '1.51';


docker descriptor => 'OCIDescriptor', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageSummary - One entry of the C<200> response to C<GET /images/json>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageSummary> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /images/json> and the C<Images> field of the C<200>
response to C<GET /system/df>.

=head2 id

ID is the content-addressable ID of an image.

This identifier is a content-addressable digest calculated from the image's
configuration (which includes the digests of layers used by the image).

Note that this digest differs from the C<RepoDigests> below, which holds
digests of image manifests that reference the image. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 parent_id

ID of the parent image.

Depending on how the image was created, this field may be empty and is only
set for images that were built/created locally. This field is empty if the
image was pulled from an image registry. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 repo_tags

List of image names/tags in the local image cache that reference this image.

Multiple image tags can refer to the same image, and this list may be empty
if no tags reference the image, in which case the image is "untagged", in
which case it can still be referenced by its ID. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 repo_digests

List of content-addressable digests of locally available image manifests
that the image is referenced from. Multiple manifests can refer to the same
image.

These digests are usually only available if the image was either pulled from
a registry, or if the image was pushed to a registry, which is when the
manifest is generated and its digest calculated. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 created

Date and time at which the image was created as a Unix timestamp (number of
seconds since EPOCH). The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 size

Total size of the image including all layers it is composed of. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 shared_size

Total size of image layers that are shared between this image and other
images.

This size is not calculated by default. C<-1> indicates that the value has
not been set / calculated. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 containers

Number of containers using this image. Includes both stopped and running
containers.

C<-1> indicates that the value has not been set / calculated. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 manifests

Manifests is a list of manifests available in this image. It provides a more
detailed view of the platform-specific image manifests or other
image-attached data like build attestations.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::ImageManifestSummary>.

=head2 descriptor

Descriptor is an OCI descriptor of the image target. In case of a
multi-platform image, this descriptor points to the OCI index or a manifest
list.

This field is only present if the daemon provides a multi-platform image
store.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::OCIDescriptor>.

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

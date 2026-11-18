package API::Docker::Type::ImageManifestSummary::Size;
# ABSTRACT: The sizes of one manifest of an image
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker total => Int, since => '1.51';


docker content => Int, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageManifestSummary::Size - The sizes of one manifest of an image

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Size> schema of the C<ImageManifestSummary>
definition in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Two
byte counts, C<Content> and C<Total>.

=head2 total

Total is the total size (in bytes) of all the locally present data (both
distributable and non-distributable) that's related to this manifest and its
children. This equal to the sum of [Content] size AND all the sizes in the
[Size] struct present in the Kind-specific data struct. For example, for an
image kind (Kind == "image") this would include the size of the image
content and unpacked image snapshots ([Size.Content] +
[ImageData.Size.Unpacked]).

=head2 content

Content is the size (in bytes) of all the locally present content in the
content store (e.g. image config, layers) referenced by this manifest and
its children. This only includes blobs in the content store.

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

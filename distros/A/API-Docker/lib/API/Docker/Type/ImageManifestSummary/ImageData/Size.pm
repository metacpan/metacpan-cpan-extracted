package API::Docker::Type::ImageManifestSummary::ImageData::Size;
# ABSTRACT: The unpacked size of an image manifest
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker unpacked => Int, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageManifestSummary::ImageData::Size - The unpacked size of an image manifest

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Size> schema of
C<ImageManifestSummary.ImageData> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. One byte count, C<Unpacked>.

=head2 unpacked

Unpacked is the size (in bytes) of the locally unpacked (uncompressed) image
content that's directly usable by the containers running this image. It's
independent of the distributable content - e.g. the image might still have
an unpacked data that's still used by some container even when the
distributable/compressed content is already gone.

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

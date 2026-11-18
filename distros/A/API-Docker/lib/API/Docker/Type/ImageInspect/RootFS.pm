package API::Docker::Type::ImageInspect::RootFS;
# ABSTRACT: Information about the image's RootFS, including the layer IDs
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker type => Str;


docker layers => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageInspect::RootFS - Information about the image's RootFS, including the layer IDs

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<RootFS> schema of the C<ImageInspect> definition
in C<spec/v1.51.yaml>.

=head2 type

Undocumented upstream. How the root filesystem is stored. C<layers> is the
only value the swagger shows, and the only one measured: C<GET
/images/{id}/json> on Podman 5.8.4 (API 1.44) answers C<"Type": "layers">.

=head2 layers

Undocumented upstream. One diff ID per layer of the image. Measured against
Podman 5.8.4 (API 1.44), a Debian-based image answers eight C<sha256:...>
digests here; the swagger's example shows two of the same form.

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

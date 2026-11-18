package API::Docker::Type::Mount::ImageOptions;
# ABSTRACT: Optional configuration for the C<image> type
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker subpath => Str, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Mount::ImageOptions - Optional configuration for the C<image> type

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<ImageOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>. The whole schema is newer than v1.44.

=head2 subpath

Source path inside the image. Must be relative without any back traversals.

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

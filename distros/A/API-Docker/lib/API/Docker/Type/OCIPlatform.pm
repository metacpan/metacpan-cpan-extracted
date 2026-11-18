package API::Docker::Type::OCIPlatform;
# ABSTRACT: Describes the platform which the image in the manifest runs on, as defined in the L<OCI Image Index Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/image-index.md>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker architecture => Str, wire => 'architecture';


docker os => Str, wire => 'os';


docker os_version => Str, wire => 'os.version';


docker os_features => [Str], wire => 'os.features';


docker variant => Str, wire => 'variant';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::OCIPlatform - Describes the platform which the image in the manifest runs on, as defined in the L<OCI Image Index Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/image-index.md>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<OCIPlatform> definition of C<spec/v1.51.yaml>.

=head2 architecture

The CPU architecture, for example C<amd64> or C<ppc64>. Serialised as
C<architecture> -- spelled out, because deriving it from the Perl name would
produce C<Architecture>.

=head2 os

The operating system, for example C<linux> or C<windows>. Serialised as
C<os> -- spelled out, because deriving it from the Perl name would produce
C<Os>.

=head2 os_version

Optional field specifying the operating system version, for example on
Windows C<10.0.19041.1165>. Serialised as C<os.version> -- spelled out,
because deriving it from the Perl name would produce C<OsVersion>.

=head2 os_features

Optional field specifying an array of strings, each listing a required OS
feature (for example on Windows C<win32k>). Serialised as C<os.features> --
spelled out, because deriving it from the Perl name would produce
C<OsFeatures>.

=head2 variant

Optional field specifying a variant of the CPU, for example C<v7> to specify
ARMv7 when architecture is C<arm>. Serialised as C<variant> -- spelled out,
because deriving it from the Perl name would produce C<Variant>.

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

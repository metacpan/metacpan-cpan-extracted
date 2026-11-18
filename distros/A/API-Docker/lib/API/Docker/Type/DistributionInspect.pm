package API::Docker::Type::DistributionInspect;
# ABSTRACT: Describes the result obtained from contacting the registry to retrieve image metadata
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::OCIDescriptor;
use API::Docker::Type::OCIPlatform;
use namespace::clean;


docker descriptor => 'OCIDescriptor', required => 1;


docker platforms => [ 'OCIPlatform' ], required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::DistributionInspect - Describes the result obtained from contacting the registry to retrieve image metadata

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<DistributionInspect> definition of C<spec/v1.51.yaml>.

=head2 descriptor

A descriptor struct containing digest, media type, and size, as defined in
the L<OCI Content Descriptors
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>.
See L<API::Docker::Type::OCIDescriptor>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 platforms

An array containing all platforms supported by the image. See
L<API::Docker::Type::OCIPlatform>. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

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

package API::Docker::Type::ImageManifestSummary::AttestationData;
# ABSTRACT: The image data for the attestation manifest
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker for => Str, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageManifestSummary::AttestationData - The image data for the attestation manifest

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<AttestationData> schema of the
C<ImageManifestSummary> definition in C<spec/v1.51.yaml>.

This field is only populated when Kind is "attestation".

=head2 for

The digest of the image manifest that this attestation is for.

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

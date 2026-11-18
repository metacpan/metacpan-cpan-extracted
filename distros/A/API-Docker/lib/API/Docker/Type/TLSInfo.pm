package API::Docker::Type::TLSInfo;
# ABSTRACT: Information about the issuer of leaf TLS certificates and the trusted root CA certificate
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker trust_root => Str;


docker cert_issuer_subject => Str;


docker cert_issuer_public_key => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TLSInfo - Information about the issuer of leaf TLS certificates and the trusted root CA certificate

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<TLSInfo> definition of C<spec/v1.51.yaml>.

=head2 trust_root

The root CA certificate(s) that are used to validate leaf TLS certificates.

=head2 cert_issuer_subject

The base64-url-safe-encoded raw subject bytes of the issuer.

=head2 cert_issuer_public_key

The base64-url-safe-encoded raw public key bytes of the issuer.

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

package API::Docker::Type::SwarmSpec::CAConfig;
# ABSTRACT: CA configuration
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::SwarmSpec::CAConfig::ExternalCA;
use namespace::clean;


docker node_cert_expiry => Int;


docker external_cas => [ 'SwarmSpec::CAConfig::ExternalCA' ],
  wire => 'ExternalCAs';


docker signing_ca_cert => Str, wire => 'SigningCACert';


docker signing_ca_key => Str, wire => 'SigningCAKey';


docker force_rotate => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SwarmSpec::CAConfig - CA configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<CAConfig> schema of the C<SwarmSpec> definition
in C<spec/v1.51.yaml>.

=head2 node_cert_expiry

The duration node certificates are issued for.

=head2 external_cas

Configuration for forwarding signing requests to an external certificate
authority. See L<API::Docker::Type::SwarmSpec::CAConfig::ExternalCA>.
Serialised as C<ExternalCAs> -- spelled out, because deriving it from the
Perl name would produce C<ExternalCas>.

=head2 signing_ca_cert

The desired signing CA certificate for all swarm node TLS leaf certificates,
in PEM format. Serialised as C<SigningCACert> -- spelled out, because
deriving it from the Perl name would produce C<SigningCaCert>.

=head2 signing_ca_key

The desired signing CA key for all swarm node TLS leaf certificates, in PEM
format. Serialised as C<SigningCAKey> -- spelled out, because deriving it
from the Perl name would produce C<SigningCaKey>.

=head2 force_rotate

An integer whose purpose is to force swarm to generate a new signing CA
certificate and key, if none have been specified in C<SigningCACert> and
C<SigningCAKey>.

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

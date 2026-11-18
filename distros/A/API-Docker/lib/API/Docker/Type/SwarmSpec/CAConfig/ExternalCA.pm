package API::Docker::Type::SwarmSpec::CAConfig::ExternalCA;
# ABSTRACT: One entry of C<SwarmSpec.CAConfig.ExternalCAs>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker protocol => Str, enum => [qw( cfssl )];


docker url => Str, wire => 'URL';


docker options => { Str, Str };


docker ca_cert => Str, wire => 'CACert';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SwarmSpec::CAConfig::ExternalCA - One entry of C<SwarmSpec.CAConfig.ExternalCAs>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<SwarmSpec.CAConfig.ExternalCAs> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 protocol

Protocol for communication with the external CA (currently only C<cfssl> is
supported). The daemon defaults it to cfssl.

=head2 url

URL where certificate signing requests should be sent. Serialised as C<URL>
-- spelled out, because deriving it from the Perl name would produce C<Url>.

=head2 options

An object with key/value pairs that are interpreted as protocol-specific
options for the external CA driver. B<The keys are the caller's data> and
are never translated.

=head2 ca_cert

The root CA certificate (in PEM format) this external CA uses to issue TLS
certificates (assumed to be to the current swarm root CA certificate if not
provided). Serialised as C<CACert> -- spelled out, because deriving it from
the Perl name would produce C<CaCert>.

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

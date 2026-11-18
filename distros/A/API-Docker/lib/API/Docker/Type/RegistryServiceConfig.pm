package API::Docker::Type::RegistryServiceConfig;
# ABSTRACT: Daemon registry services configuration
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::IndexInfo;
use namespace::clean;


docker insecure_registry_cidrs => [Str], wire => 'InsecureRegistryCIDRs';


docker index_configs => { Str, 'IndexInfo' };


docker mirrors => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::RegistryServiceConfig - Daemon registry services configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<RegistryServiceConfig> definition of
C<spec/v1.51.yaml>.

=head2 insecure_registry_cidrs

List of IP ranges of insecure registries, using the CIDR syntax (L<RFC
4632|https://tools.ietf.org/html/4632>). Insecure registries accept
un-encrypted (HTTP) and/or untrusted (HTTPS with certificates from unknown
CAs) communication.

By default, local registries (C<::1/128> and C<127.0.0.0/8>) are configured
as insecure. All other registries are secure. Communicating with an insecure
registry is not possible if the daemon assumes that registry is secure.

This configuration override this behavior, insecure communication with
registries whose resolved IP address is within the subnet described by the
CIDR syntax.

Registries can also be marked insecure by hostname. Those registries are
listed under C<IndexConfigs> and have their C<Secure> field set to C<false>.

> B<Warning>: Using this option can be useful when running a local >
registry, but introduces security vulnerabilities. This option > should
therefore ONLY be used for testing purposes. For increased > security, users
should add their CA to their system's list of trusted > CAs instead of
enabling this option. Serialised as C<InsecureRegistryCIDRs> -- spelled out,
because deriving it from the Perl name would produce
C<InsecureRegistryCidrs>.

=head2 index_configs

Undocumented upstream. One L<API::Docker::Type::IndexInfo> per registry the
daemon knows, keyed by the registry's own name -- C<docker.io>,
C<127.0.0.1:5000> and C<< [2001:db8:a0b:12f0::1]:80 >> among the swagger's
examples. L</insecure_registry_cidrs> describes this map as where a registry
marked insecure by hostname is listed, with its C<Secure> set to false.
Measured against Podman 5.8.4 (API 1.44), C<GET /info> answers an empty map
here. See L<API::Docker::Type::IndexInfo>. B<The keys are the caller's data>
and are never translated.

=head2 mirrors

List of registry URLs that act as a mirror for the official (C<docker.io>)
registry.

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

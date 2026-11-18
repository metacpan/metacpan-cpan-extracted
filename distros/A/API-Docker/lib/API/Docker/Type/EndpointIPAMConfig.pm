package API::Docker::Type::EndpointIPAMConfig;
# ABSTRACT: An endpoint's IPAM configuration
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker ipv4_address => Str, wire => 'IPv4Address';


docker ipv6_address => Str, wire => 'IPv6Address';


docker link_local_ips => [Str], wire => 'LinkLocalIPs';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EndpointIPAMConfig - An endpoint's IPAM configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EndpointIPAMConfig> definition of C<spec/v1.51.yaml>.

=head2 ipv4_address

Undocumented upstream. An IPv4 address for the endpoint, C<172.20.30.33> in
the swagger's example. This is the address configured; the one the endpoint
ends up with is reported separately as
L<API::Docker::Type::EndpointSettings/ip_address>. Serialised as
C<IPv4Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv4Address>.

=head2 ipv6_address

Undocumented upstream. The IPv6 counterpart of L</ipv4_address>,
C<2001:db8:abcd::3033> in the swagger's example. Serialised as
C<IPv6Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv6Address>.

=head2 link_local_ips

Undocumented upstream. Link-local addresses for the endpoint. The swagger's
example holds one of each family, C<< ["169.254.34.68", "fe80::3468"] >>.
Serialised as C<LinkLocalIPs> -- spelled out, because deriving it from the
Perl name would produce C<LinkLocalIps>.

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

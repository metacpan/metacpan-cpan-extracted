package API::Docker::Type::EndpointSettings;
# ABSTRACT: Configuration for a network endpoint
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointIPAMConfig;
use namespace::clean;


docker ipam_config => 'EndpointIPAMConfig', wire => 'IPAMConfig';


docker links => [Str];


docker mac_address => Str;


docker aliases => [Str];


docker driver_opts => { Str, Str };


docker gw_priority => Int, since => '1.51';


docker network_id => Str, wire => 'NetworkID';


docker endpoint_id => Str, wire => 'EndpointID';


docker gateway => Str;


docker ip_address => Str, wire => 'IPAddress';


docker ip_prefix_len => Int, wire => 'IPPrefixLen';


docker ipv6_gateway => Str, wire => 'IPv6Gateway';


docker global_ipv6_address => Str, wire => 'GlobalIPv6Address';


docker global_ipv6_prefix_len => Int, wire => 'GlobalIPv6PrefixLen';


docker dns_names => [Str], wire => 'DNSNames', since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EndpointSettings - Configuration for a network endpoint

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EndpointSettings> definition of C<spec/v1.51.yaml>.

=head2 ipam_config

EndpointIPAMConfig represents an endpoint's IPAM configuration. See
L<API::Docker::Type::EndpointIPAMConfig>. Serialised as C<IPAMConfig> --
spelled out, because deriving it from the Perl name would produce
C<IpamConfig>.

=head2 links

Undocumented upstream. Container links for this endpoint. The swagger
describes the same field name under L<API::Docker::Type::HostConfig/links>
as a list of links in the form C<container_name:alias>; the example given
here is the bare C<< ["container_1", "container_2"] >>.

=head2 mac_address

MAC address for the endpoint on this network. The network driver might
ignore this parameter.

=head2 aliases

Undocumented upstream. The network aliases of this endpoint. L</dns_names>
names them as one of the four things an endpoint's DNS names are built from
-- the container name, its network aliases, its short ID and its hostname.
The swagger's example is C<< ["server_x", "server_y"] >>.

=head2 driver_opts

DriverOpts is a mapping of driver options and values. These options are
passed directly to the driver and are driver specific. B<The keys are the
caller's data> and are never translated.

=head2 gw_priority

This property determines which endpoint will provide the default gateway for
a container. The endpoint with the highest priority will be used. If
multiple endpoints have the same priority, endpoints are lexicographically
sorted based on their network name, and the one that sorts first is picked.

=head2 network_id

Unique ID of the network. Serialised as C<NetworkID> -- spelled out, because
deriving it from the Perl name would produce C<NetworkId>.

=head2 endpoint_id

Unique ID for the service endpoint in a Sandbox. Serialised as C<EndpointID>
-- spelled out, because deriving it from the Perl name would produce
C<EndpointId>.

=head2 gateway

Gateway address for this network.

=head2 ip_address

IPv4 address. Serialised as C<IPAddress> -- spelled out, because deriving it
from the Perl name would produce C<IpAddress>.

=head2 ip_prefix_len

Mask length of the IPv4 address. Serialised as C<IPPrefixLen> -- spelled
out, because deriving it from the Perl name would produce C<IpPrefixLen>.

=head2 ipv6_gateway

IPv6 gateway address. Serialised as C<IPv6Gateway> -- spelled out, because
deriving it from the Perl name would produce C<Ipv6Gateway>.

=head2 global_ipv6_address

Global IPv6 address. Serialised as C<GlobalIPv6Address> -- spelled out,
because deriving it from the Perl name would produce C<GlobalIpv6Address>.

=head2 global_ipv6_prefix_len

Mask length of the global IPv6 address. Serialised as C<GlobalIPv6PrefixLen>
-- spelled out, because deriving it from the Perl name would produce
C<GlobalIpv6PrefixLen>.

=head2 dns_names

List of all DNS names an endpoint has on a specific network. This list is
based on the container name, network aliases, container short ID, and
hostname.

These DNS names are non-fully qualified but can contain several dots. You
can get fully qualified DNS names by appending C<< .<network-name> >>. For
instance, if container name is C<my.ctr> and the network is named
C<testnet>, C<DNSNames> will contain C<my.ctr> and the FQDN will be
C<my.ctr.testnet>. Serialised as C<DNSNames> -- spelled out, because
deriving it from the Perl name would produce C<DnsNames>.

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

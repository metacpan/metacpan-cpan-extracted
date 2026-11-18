package API::Docker::Type::NetworkSettings;
# ABSTRACT: NetworkSettings exposes the network settings in the API
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Address;
use API::Docker::Type::EndpointSettings;
use API::Docker::Type::PortBinding;
use namespace::clean;


docker bridge => Str;


docker sandbox_id => Str, wire => 'SandboxID';


docker hairpin_mode => Bool;


docker link_local_ipv6_address => Str, wire => 'LinkLocalIPv6Address';


docker link_local_ipv6_prefix_len => Int, wire => 'LinkLocalIPv6PrefixLen';


docker ports => { Str, [ 'PortBinding' ] };


docker sandbox_key => Str;


docker secondary_ip_addresses => [ 'Address' ],
  wire => 'SecondaryIPAddresses';


docker secondary_ipv6_addresses => [ 'Address' ],
  wire => 'SecondaryIPv6Addresses';


docker endpoint_id => Str, wire => 'EndpointID';


docker gateway => Str;


docker global_ipv6_address => Str, wire => 'GlobalIPv6Address';


docker global_ipv6_prefix_len => Int, wire => 'GlobalIPv6PrefixLen';


docker ip_address => Str, wire => 'IPAddress';


docker ip_prefix_len => Int, wire => 'IPPrefixLen';


docker ipv6_gateway => Str, wire => 'IPv6Gateway';


docker mac_address => Str;


docker networks => { Str, 'EndpointSettings' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NetworkSettings - NetworkSettings exposes the network settings in the API

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NetworkSettings> definition of C<spec/v1.51.yaml>.

=head2 bridge

Name of the default bridge interface when dockerd's --bridge flag is set.

Deprecated: This field is only set when the daemon is started with the
--bridge flag specified.

=head2 sandbox_id

SandboxID uniquely represents a container's network stack. Serialised as
C<SandboxID> -- spelled out, because deriving it from the Perl name would
produce C<SandboxId>.

=head2 hairpin_mode

Indicates if hairpin NAT should be enabled on the virtual interface.

Deprecated: This field is never set and will be removed in a future release.

=head2 link_local_ipv6_address

IPv6 unicast address using the link-local prefix.

Deprecated: This field is never set and will be removed in a future release.
Serialised as C<LinkLocalIPv6Address> -- spelled out, because deriving it
from the Perl name would produce C<LinkLocalIpv6Address>.

=head2 link_local_ipv6_prefix_len

Prefix length of the IPv6 unicast address.

Deprecated: This field is never set and will be removed in a future release.
Serialised as C<LinkLocalIPv6PrefixLen> -- spelled out, because deriving it
from the Perl name would produce C<LinkLocalIpv6PrefixLen>.

=head2 ports

PortMap describes the mapping of container ports to host ports, using the
container's port-number and protocol as key in the format C<<
<port>/<protocol> >>, for example, C<80/udp>.

If a container's port is mapped for multiple protocols, separate entries are
added to the mapping table. See L<API::Docker::Type::PortBinding>. B<The
keys are the caller's data> and are never translated.

=head2 sandbox_key

SandboxKey is the full path of the netns handle.

=head2 secondary_ip_addresses

Deprecated: This field is never set and will be removed in a future release.
See L<API::Docker::Type::Address>. Serialised as C<SecondaryIPAddresses> --
spelled out, because deriving it from the Perl name would produce
C<SecondaryIpAddresses>.

=head2 secondary_ipv6_addresses

Deprecated: This field is never set and will be removed in a future release.
See L<API::Docker::Type::Address>. Serialised as C<SecondaryIPv6Addresses>
-- spelled out, because deriving it from the Perl name would produce
C<SecondaryIpv6Addresses>.

=head2 endpoint_id

EndpointID uniquely represents a service endpoint in a Sandbox.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<EndpointID> -- spelled out, because deriving
it from the Perl name would produce C<EndpointId>.

=head2 gateway

Gateway address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0.

=head2 global_ipv6_address

Global IPv6 address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<GlobalIPv6Address> -- spelled out, because
deriving it from the Perl name would produce C<GlobalIpv6Address>.

=head2 global_ipv6_prefix_len

Mask length of the global IPv6 address.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<GlobalIPv6PrefixLen> -- spelled out, because
deriving it from the Perl name would produce C<GlobalIpv6PrefixLen>.

=head2 ip_address

IPv4 address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPAddress> -- spelled out, because deriving
it from the Perl name would produce C<IpAddress>.

=head2 ip_prefix_len

Mask length of the IPv4 address.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPPrefixLen> -- spelled out, because
deriving it from the Perl name would produce C<IpPrefixLen>.

=head2 ipv6_gateway

IPv6 gateway address for this network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPv6Gateway> -- spelled out, because
deriving it from the Perl name would produce C<Ipv6Gateway>.

=head2 mac_address

MAC address for the container on the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0.

=head2 networks

Information about all networks that the container is connected to. See
L<API::Docker::Type::EndpointSettings>. B<The keys are the caller's data>
and are never translated.

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

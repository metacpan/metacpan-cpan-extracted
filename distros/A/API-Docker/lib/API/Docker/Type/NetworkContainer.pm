package API::Docker::Type::NetworkContainer;
# ABSTRACT: One value of C<Network.Containers>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker endpoint_id => Str, wire => 'EndpointID';


docker mac_address => Str;


docker ipv4_address => Str, wire => 'IPv4Address';


docker ipv6_address => Str, wire => 'IPv6Address';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NetworkContainer - One value of C<Network.Containers>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NetworkContainer> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one value of C<Network.Containers>. The keys of that map are
container IDs, and the swagger describes the field holding it as containing
the endpoints attached to the network.

=head2 name

Undocumented upstream. The container's name, C<container_1> in the swagger's
example.

=head2 endpoint_id

Undocumented upstream. The endpoint's ID, the value the swagger describes
under L<API::Docker::Type::EndpointSettings/endpoint_id> as unique for a
service endpoint in a sandbox. Serialised as C<EndpointID> -- spelled out,
because deriving it from the Perl name would produce C<EndpointId>.

=head2 mac_address

Undocumented upstream. The endpoint's MAC address on this network, which the
swagger notes under L<API::Docker::Type::EndpointSettings/mac_address> a
network driver may ignore.

=head2 ipv4_address

Undocumented upstream. The address with its prefix length, C<172.19.0.2/16>
in the swagger's example -- not the bare address
L<API::Docker::Type::EndpointSettings/ip_address> carries. Serialised as
C<IPv4Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv4Address>.

=head2 ipv6_address

Undocumented upstream. The IPv6 counterpart of L</ipv4_address>, empty in
the swagger's example, where the network has none. Serialised as
C<IPv6Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv6Address>.

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

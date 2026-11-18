package API::Docker::Type::Network;
# ABSTRACT: One entry of the C<200> response to C<GET /networks>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ConfigReference;
use API::Docker::Type::IPAM;
use API::Docker::Type::NetworkContainer;
use API::Docker::Type::NetworkStatus;
use API::Docker::Type::PeerInfo;
use namespace::clean;


docker name => Str;


docker id => Str;


docker created => Str;


docker scope => Str;


docker driver => Str;


docker enable_ipv4 => Bool, wire => 'EnableIPv4', since => '1.51';


docker enable_ipv6 => Bool, wire => 'EnableIPv6';


docker ipam => 'IPAM', wire => 'IPAM';


docker internal => Bool;


docker attachable => Bool;


docker ingress => Bool;


docker config_from => 'ConfigReference';


docker config_only => Bool;


docker containers => { Str, 'NetworkContainer' };


docker options => { Str, Str };


docker labels => { Str, Str };


docker peers => [ 'PeerInfo' ];


docker status => 'NetworkStatus', since => '1.55';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Network - One entry of the C<200> response to C<GET /networks>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Network> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /networks> and the body of the C<200> response to
C<GET /networks/{id}>.

=head2 name

Name of the network.

=head2 id

ID that uniquely identifies a network on a single machine.

=head2 created

Date and time at which the network was created in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 scope

The level at which the network exists (e.g. C<swarm> for cluster-wide or
C<local> for machine level).

=head2 driver

The name of the driver used to create the network (e.g. C<bridge>,
C<overlay>).

=head2 enable_ipv4

Whether the network was created with IPv4 enabled. Serialised as
C<EnableIPv4> -- spelled out, because deriving it from the Perl name would
produce C<EnableIpv4>.

=head2 enable_ipv6

Whether the network was created with IPv6 enabled. Serialised as
C<EnableIPv6> -- spelled out, because deriving it from the Perl name would
produce C<EnableIpv6>.

=head2 ipam

Undocumented upstream. The network's address management -- which IPAM
driver, that driver's options, and the pools it allocates from. Measured
against Podman 5.8.4 (API 1.44), the default bridge answers C<< {"Driver":
"default", "Options": {"driver": "host-local"}, "Config": [{"Subnet":
"10.88.0.0/16", "Gateway": "10.88.0.1"}]} >>. See
L<API::Docker::Type::IPAM>. Serialised as C<IPAM> -- spelled out, because
deriving it from the Perl name would produce C<Ipam>.

=head2 internal

Whether the network is created to only allow internal networking
connectivity. The daemon defaults it to false.

=head2 attachable

Whether a global / swarm scope network is manually attachable by regular
containers from workers in swarm mode. The daemon defaults it to false.

=head2 ingress

Whether the network is providing the routing-mesh for the swarm cluster. The
daemon defaults it to false.

=head2 config_from

The config-only network source to provide the configuration for this
network. See L<API::Docker::Type::ConfigReference>.

=head2 config_only

Whether the network is a config-only network. Config-only networks are
placeholder networks for network configurations to be used by other
networks. Config-only networks cannot be used directly to run containers or
services. The daemon defaults it to false.

=head2 containers

Contains endpoints attached to the network. See
L<API::Docker::Type::NetworkContainer>. B<The keys are the caller's data>
and are never translated.

=head2 options

Network-specific options uses when creating the network. B<The keys are the
caller's data> and are never translated.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 peers

List of peer nodes for an overlay network. This field is only present for
overlay networks, and omitted for other network types. See
L<API::Docker::Type::PeerInfo>.

=head2 status

Provides runtime information about the network such as the number of
allocated IPs. See L<API::Docker::Type::NetworkStatus>.

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

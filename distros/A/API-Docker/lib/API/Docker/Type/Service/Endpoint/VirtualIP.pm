package API::Docker::Type::Service::Endpoint::VirtualIP;
# ABSTRACT: One entry of C<Service.Endpoint.VirtualIPs>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker network_id => Str, wire => 'NetworkID';


docker addr => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service::Endpoint::VirtualIP - One entry of C<Service.Endpoint.VirtualIPs>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Service.Endpoint.VirtualIPs>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 network_id

Undocumented upstream. The network the address is on,
C<4qvuz4ko70xaltuqbt8956gd1> on both entries of the swagger's C<Service>
example. Serialised as C<NetworkID> -- spelled out, because deriving it from
the Perl name would produce C<NetworkId>.

=head2 addr

Undocumented upstream. The address with its prefix length, C<10.255.0.2/16>
in that example -- CIDR, the way
L<API::Docker::Type::NetworkContainer/ipv4_address> is and
L<API::Docker::Type::EndpointSettings/ip_address> is not.

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

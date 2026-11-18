package API::Docker::Type::Service::Endpoint;
# ABSTRACT: The resolved endpoint of a service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use API::Docker::Type::EndpointSpec;
use API::Docker::Type::Service::Endpoint::VirtualIP;
use namespace::clean;


docker spec => 'EndpointSpec';


docker ports => [ 'EndpointPortConfig' ];


docker virtual_ips => [ 'Service::Endpoint::VirtualIP' ],
  wire => 'VirtualIPs';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service::Endpoint - The resolved endpoint of a service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Endpoint> schema of the C<Service> definition in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. The specification
a service was asked for, alongside the ports and virtual IPs the swarm
actually gave it.

=head2 spec

Properties that can be configured to access and load balance a service. See
L<API::Docker::Type::EndpointSpec>.

=head2 ports

Undocumented upstream. The ports as published. In the swagger's C<Service>
example they are the very entry C<Spec.Ports> asked for -- C<tcp>, target
C<6379>, published C<30001>. See L<API::Docker::Type::EndpointPortConfig>.

=head2 virtual_ips

Undocumented upstream. One entry per virtual IP the routing mesh gave the
service. The swagger's C<Service> example carries two, C<10.255.0.2/16> and
C<10.255.0.3/16>, both on the same network. See
L<API::Docker::Type::Service::Endpoint::VirtualIP>. Serialised as
C<VirtualIPs> -- spelled out, because deriving it from the Perl name would
produce C<VirtualIps>.

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

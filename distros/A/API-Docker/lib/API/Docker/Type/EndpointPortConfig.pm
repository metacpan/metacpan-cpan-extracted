package API::Docker::Type::EndpointPortConfig;
# ABSTRACT: One entry of C<EndpointSpec.Ports>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker protocol => Str, enum => [qw( tcp udp sctp )];


docker target_port => Int;


docker published_port => Int;


docker publish_mode => Str, enum => [qw( ingress host )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EndpointPortConfig - One entry of C<EndpointSpec.Ports>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EndpointPortConfig> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one entry of C<EndpointSpec.Ports>, C<PortStatus.Ports> and
C<Service.Endpoint.Ports>.

=head2 name

Undocumented upstream.

=head2 protocol

Undocumented upstream. The transport protocol of the published port, C<tcp>
in the swagger's C<Service> example. The same enumeration appears on a
container's own port list as L<API::Docker::Type::Port/type>. The swagger
enumerates C<tcp>, C<udp> and C<sctp>.

=head2 target_port

The port inside the container.

=head2 published_port

The port on the swarm hosts.

=head2 publish_mode

The mode in which port is published.

=over 4

=item * "ingress" makes the target port accessible on every node, regardless
of whether there is a task for the service running on that node or not.

=item * "host" bypasses the routing mesh and publish the port directly on
the swarm node where that service is running.

=back

The daemon defaults it to ingress.

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

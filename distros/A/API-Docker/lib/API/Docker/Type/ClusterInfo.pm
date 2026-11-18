package API::Docker::Type::ClusterInfo;
# ABSTRACT: Information about the swarm as is returned by the "/info" endpoint
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::SwarmSpec;
use API::Docker::Type::TLSInfo;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker spec => 'SwarmSpec';


docker tls_info => 'TLSInfo', wire => 'TLSInfo';


docker root_rotation_in_progress => Bool;


docker data_path_port => Int;


docker default_addr_pool => [Str];


docker subnet_size => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterInfo - Information about the swarm as is returned by the "/info" endpoint

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ClusterInfo> definition of C<spec/v1.51.yaml>.

Join-tokens are not included.

=head2 id

The ID of the swarm. Serialised as C<ID> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Date and time at which the swarm was initialised in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 updated_at

Date and time at which the swarm was last updated in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 spec

User modifiable swarm configuration. See L<API::Docker::Type::SwarmSpec>.

=head2 tls_info

Information about the issuer of leaf TLS certificates and the trusted root
CA certificate. See L<API::Docker::Type::TLSInfo>. Serialised as C<TLSInfo>
-- spelled out, because deriving it from the Perl name would produce
C<TlsInfo>.

=head2 root_rotation_in_progress

Whether there is currently a root CA rotation in progress for the swarm.

=head2 data_path_port

DataPathPort specifies the data path port number for data traffic.
Acceptable port range is 1024 to 49151. If no port is set or is set to 0,
the default port (4789) is used.

=head2 default_addr_pool

Default Address Pool specifies default subnet pools for global scope
networks.

=head2 subnet_size

SubnetSize specifies the subnet size of the networks created from the
default subnet pool.

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

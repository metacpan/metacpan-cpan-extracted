package API::Docker::Type::NodeDescription;
# ABSTRACT: NodeDescription encapsulates the properties of the Node as reported by the agent
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EngineDescription;
use API::Docker::Type::Platform;
use API::Docker::Type::ResourceObject;
use API::Docker::Type::TLSInfo;
use namespace::clean;


docker hostname => Str;


docker platform => 'Platform';


docker resources => 'ResourceObject';


docker engine => 'EngineDescription';


docker tls_info => 'TLSInfo', wire => 'TLSInfo';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NodeDescription - NodeDescription encapsulates the properties of the Node as reported by the agent

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NodeDescription> definition of C<spec/v1.51.yaml>.

=head2 hostname

Undocumented upstream. The node's hostname, C<bf3067039e47> in the swagger's
example. As the definition above says, it is what the agent reports, not
what a manager was told.

=head2 platform

Platform represents the platform (Arch/OS). See
L<API::Docker::Type::Platform>.

=head2 resources

An object describing the resources which can be advertised by a node and
requested by a task. See L<API::Docker::Type::ResourceObject>.

=head2 engine

EngineDescription provides information about an engine. See
L<API::Docker::Type::EngineDescription>.

=head2 tls_info

Information about the issuer of leaf TLS certificates and the trusted root
CA certificate. See L<API::Docker::Type::TLSInfo>. Serialised as C<TLSInfo>
-- spelled out, because deriving it from the Perl name would produce
C<TlsInfo>.

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

package API::Docker::Type::Node;
# ABSTRACT: One entry of the C<200> response to C<GET /nodes>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ManagerStatus;
use API::Docker::Type::NodeDescription;
use API::Docker::Type::NodeSpec;
use API::Docker::Type::NodeStatus;
use API::Docker::Type::ObjectVersion;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker spec => 'NodeSpec';


docker description => 'NodeDescription';


docker status => 'NodeStatus';


docker manager_status => 'ManagerStatus';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Node - One entry of the C<200> response to C<GET /nodes>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Node> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /nodes> and the body of the C<200> response to
C<GET /nodes/{id}>.

=head2 id

Undocumented upstream. The node's ID in the swarm, C<24ifsmvkjbyhk> in the
swagger's example, and what the C</nodes/{id}> endpoints take in their path.
Serialised as C<ID> -- spelled out, because deriving it from the Perl name
would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Date and time at which the node was added to the swarm in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 updated_at

Date and time at which the node was last updated in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 spec

Undocumented upstream. The name, role, availability and labels an operator
set on the node -- C<< {"Name": "node-name", "Role": "manager",
"Availability": "active", "Labels": {"foo": "bar"}} >> in that definition's
own example. L</description> is what the node itself reports back instead.
See L<API::Docker::Type::NodeSpec>.

=head2 description

NodeDescription encapsulates the properties of the Node as reported by the
agent. See L<API::Docker::Type::NodeDescription>.

=head2 status

NodeStatus represents the status of a node. See
L<API::Docker::Type::NodeStatus>.

=head2 manager_status

ManagerStatus represents the status of a manager. See
L<API::Docker::Type::ManagerStatus>.

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

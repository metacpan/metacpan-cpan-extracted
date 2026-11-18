package API::Docker::Type::SwarmInfo;
# ABSTRACT: Represents generic information about swarm
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ClusterInfo;
use API::Docker::Type::PeerNode;
use namespace::clean;


docker node_id => Str, wire => 'NodeID';


docker node_addr => Str;


docker local_node_state => Str,
  enum => [ '', 'inactive', 'pending', 'active', 'error', 'locked' ];


docker control_available => Bool;


docker error => Str;


docker remote_managers => [ 'PeerNode' ];


docker nodes => Int;


docker managers => Int;


docker cluster => 'ClusterInfo';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SwarmInfo - Represents generic information about swarm

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<SwarmInfo> definition of C<spec/v1.51.yaml>.

=head2 node_id

Unique identifier of for this node in the swarm. The daemon defaults it to .
Serialised as C<NodeID> -- spelled out, because deriving it from the Perl
name would produce C<NodeId>.

=head2 node_addr

IP address at which this node can be reached by other nodes in the swarm.
The daemon defaults it to .

=head2 local_node_state

Current local status of this node. The swagger enumerates the empty string,
C<inactive>, C<pending>, C<active>, C<error> and C<locked>.

=head2 control_available

Undocumented upstream. A boolean, defaulted to C<false> upstream and C<true>
in the example, standing beside L</local_node_state> and L</managers>.
Measured against Podman 5.8.4 (API 1.44), C<GET /info> answers a complete
C<Swarm> block -- C<ControlAvailable> C<false>, C<LocalNodeState>
C<inactive> -- on an engine running no swarm at all.

=head2 error

Undocumented upstream. Defaulted to the empty string upstream, which is also
what that same Podman 5.8.4 measurement answers.

=head2 remote_managers

List of ID's and addresses of other managers in the swarm. See
L<API::Docker::Type::PeerNode>. The daemon defaults it to null.

=head2 nodes

Total number of nodes in the swarm.

=head2 managers

Total number of managers in the swarm.

=head2 cluster

ClusterInfo represents information about the swarm as is returned by the
"/info" endpoint. See L<API::Docker::Type::ClusterInfo>.

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

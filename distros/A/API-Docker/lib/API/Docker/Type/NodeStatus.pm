package API::Docker::Type::NodeStatus;
# ABSTRACT: The status of a node
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker state => Str, enum => [qw( unknown down ready disconnected )];


docker message => Str;


docker addr => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NodeStatus - The status of a node

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NodeStatus> definition of C<spec/v1.51.yaml>.

It provides the current status of the node, as seen by the manager.

=head2 state

NodeState represents the state of a node. The swagger enumerates C<unknown>,
C<down>, C<ready> and C<disconnected>.

=head2 message

Undocumented upstream. Free text about the node from the manager that
watches it -- the human-readable half of L</state>. The swagger's example is
the empty string.

=head2 addr

IP address of the node.

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

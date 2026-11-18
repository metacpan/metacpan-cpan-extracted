package API::Docker::Type::ClusterVolume::PublishStatus;
# ABSTRACT: One entry of C<ClusterVolume.PublishStatus>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker node_id => Str, wire => 'NodeID', since => '1.44';


docker state => Str, since => '1.44',
  enum => [qw(
    pending-publish published pending-node-unpublish
    pending-controller-unpublish
  )];


docker publish_context => { Str, Str }, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolume::PublishStatus - One entry of C<ClusterVolume.PublishStatus>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<ClusterVolume.PublishStatus>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 node_id

The ID of the Swarm node the volume is published on. Serialised as C<NodeID>
-- spelled out, because deriving it from the Perl name would produce
C<NodeId>.

=head2 state

The published state of the volume.

=over 4

=item * C<pending-publish> The volume should be published to this node, but
the call to the controller plugin to do so has not yet been successfully
completed.

=item * C<published> The volume is published successfully to the node.

=item * C<pending-node-unpublish> The volume should be unpublished from the
node, and the manager is awaiting confirmation from the worker that it has
done so.

=item * C<pending-controller-unpublish> The volume is successfully
unpublished from the node, but has not yet been successfully unpublished on
the controller.

=back

=head2 publish_context

A map of strings to strings returned by the CSI controller plugin when a
volume is published. B<The keys are the caller's data> and are never
translated.

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

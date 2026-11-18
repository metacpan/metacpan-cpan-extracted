package API::Docker::Type::TaskSpec::NetworkAttachmentSpec;
# ABSTRACT: Read-only spec type for non-swarm containers attached to swarm overlay networks
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker container_id => Str, wire => 'ContainerID';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::NetworkAttachmentSpec - Read-only spec type for non-swarm containers attached to swarm overlay networks

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<NetworkAttachmentSpec> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=head2 container_id

ID of the container represented by this task. Serialised as C<ContainerID>
-- spelled out, because deriving it from the Perl name would produce
C<ContainerId>.

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

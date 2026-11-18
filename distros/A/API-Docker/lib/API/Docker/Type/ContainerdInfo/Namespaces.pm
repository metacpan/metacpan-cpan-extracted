package API::Docker::Type::ContainerdInfo::Namespaces;
# ABSTRACT: The namespaces that the daemon uses for running containers and plugins in containerd
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker containers => Str, since => '1.51';


docker plugins => Str, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerdInfo::Namespaces - The namespaces that the daemon uses for running containers and plugins in containerd

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Namespaces> schema of the C<ContainerdInfo>
definition in C<spec/v1.51.yaml>.

These namespaces can be configured in the daemon configuration, and are
considered to be used exclusively by the daemon, Tampering with the
containerd instance may cause unexpected behavior.

As these namespaces are considered to be exclusively accessed by the daemon,
it is not recommended to change these values, or to change them to a value
that is used by other systems, such as cri-containerd.

=head2 containers

The default containerd namespace used for containers managed by the daemon.

The default namespace for containers is "moby", but will be suffixed with
the C<< <uid>.<gid> >> of the remapped C<root> if user-namespaces are
enabled and the containerd image-store is used.

=head2 plugins

The default containerd namespace used for plugins managed by the daemon.

The default namespace for plugins is "plugins.moby", but will be suffixed
with the C<< <uid>.<gid> >> of the remapped C<root> if user-namespaces are
enabled and the containerd image-store is used.

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

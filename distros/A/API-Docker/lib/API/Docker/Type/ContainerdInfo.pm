package API::Docker::Type::ContainerdInfo;
# ABSTRACT: Information for connecting to the containerd instance that is used by the daemon
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerdInfo::Namespaces;
use namespace::clean;


docker address => Str, since => '1.51';


docker namespaces => 'ContainerdInfo::Namespaces', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerdInfo - Information for connecting to the containerd instance that is used by the daemon

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerdInfo> definition of C<spec/v1.51.yaml>.

This is included for debugging purposes only.

=head2 address

The address of the containerd socket.

=head2 namespaces

The namespaces that the daemon uses for running containers and plugins in
containerd. These namespaces can be configured in the daemon configuration,
and are considered to be used exclusively by the daemon, Tampering with the
containerd instance may cause unexpected behavior.

As these namespaces are considered to be exclusively accessed by the daemon,
it is not recommended to change these values, or to change them to a value
that is used by other systems, such as cri-containerd. See
L<API::Docker::Type::ContainerdInfo::Namespaces>.

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

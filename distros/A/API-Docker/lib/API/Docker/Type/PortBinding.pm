package API::Docker::Type::PortBinding;
# ABSTRACT: A binding between a host IP address and a host port
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker host_ip => Str;


docker host_port => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PortBinding - A binding between a host IP address and a host port

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PortBinding> definition of C<spec/v1.51.yaml>. These
are the values of a C<PortMap>, whose keys -- C<"80/tcp"> and the like --
are the caller's data and are never translated; see
L<API::Docker::Type::HostConfig/port_bindings>.

=head2 host_ip

Host IP address that the container's port is mapped to. The swagger's
example is C<127.0.0.1>.

=head2 host_port

Host port number that the container's port is mapped to. The swagger's
example is C<"4443">. A string on the wire, not a number.

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

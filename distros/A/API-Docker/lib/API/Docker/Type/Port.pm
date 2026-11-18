package API::Docker::Type::Port;
# ABSTRACT: An open port on a container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker ip => Str, wire => 'IP';


docker private_port => Int, required => 1;


docker public_port => Int;


docker type => Str, required => 1, enum => [qw( tcp udp sctp )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Port - An open port on a container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Port> definition of C<spec/v1.51.yaml>. One entry of
the C<Ports> array a container list answers with.

=head2 ip

Host IP address that the container's port is mapped to. Serialised as C<IP>
-- spelled out, because deriving it from the Perl name would produce C<Ip>.

=head2 private_port

Port on the container. A C<uint16>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 public_port

Port exposed on the host. A C<uint16>.

=head2 type

Undocumented upstream. The protocol the port speaks, C<tcp> in the swagger's
example for this object. The swagger enumerates C<tcp>, C<udp> and C<sctp>.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

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

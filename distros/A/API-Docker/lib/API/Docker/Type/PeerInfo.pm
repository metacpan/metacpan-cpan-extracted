package API::Docker::Type::PeerInfo;
# ABSTRACT: One peer of an overlay network
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker ip => Str, wire => 'IP';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PeerInfo - One peer of an overlay network

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PeerInfo> definition of C<spec/v1.51.yaml>.

=head2 name

ID of the peer-node in the Swarm cluster.

=head2 ip

IP-address of the peer-node in the Swarm cluster. Serialised as C<IP> --
spelled out, because deriving it from the Perl name would produce C<Ip>.

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

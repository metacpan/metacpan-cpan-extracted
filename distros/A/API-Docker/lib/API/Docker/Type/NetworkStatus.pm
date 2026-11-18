package API::Docker::Type::NetworkStatus;
# ABSTRACT: provides runtime information about the network such as the number of allocated IPs
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::IPAMStatus;
use namespace::clean;


docker ipam => 'IPAMStatus', wire => 'IPAM', since => '1.55';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NetworkStatus - provides runtime information about the network such as the number of allocated IPs

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NetworkStatus> definition of C<spec/v1.55.yaml>.

=head2 ipam

Undocumented upstream. See L<API::Docker::Type::IPAMStatus>. Serialised as
C<IPAM> -- spelled out, because deriving it from the Perl name would produce
C<Ipam>.

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

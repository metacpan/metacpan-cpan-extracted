package API::Docker::Type::IPAMStatus;
# ABSTRACT: The value of C<NetworkStatus.IPAM>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::SubnetStatus;
use namespace::clean;


docker subnets => { Str, 'SubnetStatus' }, since => '1.55';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::IPAMStatus - The value of C<NetworkStatus.IPAM>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<IPAMStatus> definition of C<spec/v1.55.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
the value of C<NetworkStatus.IPAM>.

=head2 subnets

Undocumented upstream. See L<API::Docker::Type::SubnetStatus>. B<The keys
are the caller's data> and are never translated.

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

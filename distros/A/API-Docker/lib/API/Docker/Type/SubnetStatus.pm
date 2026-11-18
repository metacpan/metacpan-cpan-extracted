package API::Docker::Type::SubnetStatus;
# ABSTRACT: One value of C<IPAMStatus.Subnets>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker ips_in_use => Int, wire => 'IPsInUse', since => '1.55';


docker dynamic_ips_available => Int,
  wire => 'DynamicIPsAvailable', since => '1.55';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SubnetStatus - One value of C<IPAMStatus.Subnets>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<SubnetStatus> definition of C<spec/v1.55.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one value of C<IPAMStatus.Subnets>.

=head2 ips_in_use

Number of IP addresses in the subnet that are in use or reserved and are
therefore unavailable for allocation, saturating at 2^64 - 1. Serialised as
C<IPsInUse> -- spelled out, because deriving it from the Perl name would
produce C<IpsInUse>.

=head2 dynamic_ips_available

Number of IP addresses within the network's IPRange for the subnet that are
available for allocation, saturating at 2^64 - 1. Serialised as
C<DynamicIPsAvailable> -- spelled out, because deriving it from the Perl
name would produce C<DynamicIpsAvailable>.

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

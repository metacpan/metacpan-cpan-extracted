package API::Docker::Type::IPAM;
# ABSTRACT: The C<IPAM> field of the body of a C<POST /networks/create> request
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::IPAMConfig;
use namespace::clean;


docker driver => Str;


docker config => [ 'IPAMConfig' ];


docker options => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::IPAM - The C<IPAM> field of the body of a C<POST /networks/create> request

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<IPAM> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the C<IPAM> field of
the body of a C<POST /networks/create> request.

=head2 driver

Name of the IPAM driver to use. The daemon defaults it to default.

=head2 config

List of IPAM configuration options, specified as a map:

    {"Subnet": <CIDR>, "IPRange": <CIDR>, "Gateway": <IP address>, "AuxAddress": <device_name:IP address>}

See L<API::Docker::Type::IPAMConfig>.

=head2 options

Driver-specific options, specified as a map. B<The keys are the caller's
data> and are never translated.

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

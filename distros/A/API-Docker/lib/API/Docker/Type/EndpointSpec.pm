package API::Docker::Type::EndpointSpec;
# ABSTRACT: Properties that can be configured to access and load balance a service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use namespace::clean;


docker mode => Str, enum => [qw( vip dnsrr )];


docker ports => [ 'EndpointPortConfig' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EndpointSpec - Properties that can be configured to access and load balance a service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EndpointSpec> definition of C<spec/v1.51.yaml>.

=head2 mode

The mode of resolution to use for internal load balancing between tasks. The
swagger enumerates C<vip> and C<dnsrr>. The daemon defaults it to vip.

=head2 ports

List of exposed ports that this service is accessible on from the outside.
Ports can only be provided if C<vip> resolution mode is used. See
L<API::Docker::Type::EndpointPortConfig>.

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

package API::Docker::Type::PortStatus;
# ABSTRACT: represents the port status of a task's host ports whose service has published host ports
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use namespace::clean;


docker ports => [ 'EndpointPortConfig' ], since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PortStatus - represents the port status of a task's host ports whose service has published host ports

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PortStatus> definition of C<spec/v1.51.yaml>.

=head2 ports

Undocumented upstream. The published ports themselves, the same entries a
service carries under L<API::Docker::Type::Service::Endpoint/ports>. See
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

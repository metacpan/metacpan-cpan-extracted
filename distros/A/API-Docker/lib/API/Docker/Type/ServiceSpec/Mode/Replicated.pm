package API::Docker::Type::ServiceSpec::Mode::Replicated;
# ABSTRACT: The replicated mode of a service, and its replica count
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker replicas => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ServiceSpec::Mode::Replicated - The replicated mode of a service, and its replica count

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Replicated> schema of C<ServiceSpec.Mode> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 replicas

Undocumented upstream. How many tasks the service should be running; C<1> in
the swagger's C<Service> example, whose one task carries
L<API::Docker::Type::Task/slot> C<1>.

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

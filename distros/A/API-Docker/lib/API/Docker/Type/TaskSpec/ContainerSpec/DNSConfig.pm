package API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig;
# ABSTRACT: Specification for DNS related configurations in resolver configuration file (C<resolv.conf>)
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker nameservers => [Str];


docker search => [Str];


docker options => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig - Specification for DNS related configurations in resolver configuration file (C<resolv.conf>)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<DNSConfig> schema of C<TaskSpec.ContainerSpec>
in C<spec/v1.51.yaml>.

=head2 nameservers

The IP addresses of the name servers.

=head2 search

A search list for host-name lookup.

=head2 options

A list of internal resolver variables to be modified (e.g., C<debug>,
C<ndots:3>, etc.).

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

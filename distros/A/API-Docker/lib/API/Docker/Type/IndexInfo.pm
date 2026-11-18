package API::Docker::Type::IndexInfo;
# ABSTRACT: Information about a registry
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker mirrors => [Str];


docker secure => Bool;


docker official => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::IndexInfo - Information about a registry

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<IndexInfo> definition of C<spec/v1.51.yaml>.

=head2 name

Name of the registry, such as "docker.io".

=head2 mirrors

List of mirrors, expressed as URIs.

=head2 secure

Indicates if the registry is part of the list of insecure registries.

If C<false>, the registry is insecure. Insecure registries accept
un-encrypted (HTTP) and/or untrusted (HTTPS with certificates from unknown
CAs) communication.

> B<Warning>: Insecure registries can be useful when running a local >
registry. However, because its use creates security vulnerabilities > it
should ONLY be enabled for testing purposes. For increased > security, users
should add their CA to their system's list of > trusted CAs instead of
enabling this option.

=head2 official

Indicates whether this is an official registry (i.e., Docker Hub /
docker.io).

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

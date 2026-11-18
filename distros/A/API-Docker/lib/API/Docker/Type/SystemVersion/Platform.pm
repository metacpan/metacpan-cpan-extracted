package API::Docker::Type::SystemVersion::Platform;
# ABSTRACT: The name of the platform the daemon reports itself as
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SystemVersion::Platform - The name of the platform the daemon reports itself as

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Platform> schema of the C<SystemVersion>
definition in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 name

Undocumented upstream. What the engine calls itself, and the two answers are
nothing alike: F<t/fixtures/system_version.json>, captured from Docker
27.4.1, carries C<"Docker Engine - Community">, while Podman 5.8.4 (API
1.44) answers C<"linux/amd64/debian-13">. Free text, not a token to branch
on.

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

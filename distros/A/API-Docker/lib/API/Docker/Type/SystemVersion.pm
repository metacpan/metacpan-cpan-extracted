package API::Docker::Type::SystemVersion;
# ABSTRACT: Response of Engine API: GET "/version"
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::SystemVersion::Component;
use API::Docker::Type::SystemVersion::Platform;
use namespace::clean;


docker platform => 'SystemVersion::Platform';


docker components => [ 'SystemVersion::Component' ];


docker version => Str;


docker api_version => Str;


docker min_api_version => Str, wire => 'MinAPIVersion';


docker git_commit => Str;


docker go_version => Str;


docker os => Str;


docker arch => Str;


docker kernel_version => Str;


docker experimental => Bool;


docker build_time => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SystemVersion - Response of Engine API: GET "/version"

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<SystemVersion> definition of C<spec/v1.51.yaml>.

=head2 platform

Undocumented upstream. One field, a name the engine gives itself. What the
two engines put in it has nothing in common; see
L<API::Docker::Type::SystemVersion::Platform/name>. See
L<API::Docker::Type::SystemVersion::Platform>.

=head2 components

Information about system components. See
L<API::Docker::Type::SystemVersion::Component>.

=head2 version

The version of the daemon.

=head2 api_version

The default (and highest) API version that is supported by the daemon.

=head2 min_api_version

The minimum API version that is supported by the daemon. Serialised as
C<MinAPIVersion> -- spelled out, because deriving it from the Perl name
would produce C<MinApiVersion>.

=head2 git_commit

The Git commit of the source code that was used to build the daemon.

=head2 go_version

The version Go used to compile the daemon, and the version of the Go runtime
in use.

=head2 os

The operating system that the daemon is running on ("linux" or "windows").

=head2 arch

Architecture of the daemon, as returned by the Go runtime (C<GOARCH>).

A full list of possible values can be found in the L<Go
documentation|https://go.dev/doc/install/source#environment>.

=head2 kernel_version

The kernel version (C<uname -r>) that the daemon is running on.

This field is omitted when empty.

=head2 experimental

Indicates if the daemon is started with experimental features enabled.

This field is omitted when empty / false.

=head2 build_time

The date and time that the daemon was compiled.

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

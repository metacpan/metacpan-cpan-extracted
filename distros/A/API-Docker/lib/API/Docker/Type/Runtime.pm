package API::Docker::Type::Runtime;
# ABSTRACT: An L<OCI compliant|https://github.com/opencontainers/runtime-spec> runtime
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker path => Str, wire => 'path';


docker runtime_args => [Str], wire => 'runtimeArgs';


docker status => { Str, Str }, wire => 'status', since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Runtime - An L<OCI compliant|https://github.com/opencontainers/runtime-spec> runtime

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Runtime> definition of C<spec/v1.51.yaml>.

The runtime is invoked by the daemon via the C<containerd> daemon. OCI
runtimes act as an interface to the Linux kernel namespaces, cgroups, and
SELinux.

=head2 path

Name and, optional, path, of the OCI executable binary.

If the path is omitted, the daemon searches the host's C<$PATH> for the
binary and uses the first result. Serialised as C<path> -- spelled out,
because deriving it from the Perl name would produce C<Path>.

=head2 runtime_args

List of command-line arguments to pass to the runtime when invoked.
Serialised as C<runtimeArgs> -- spelled out, because deriving it from the
Perl name would produce C<RuntimeArgs>.

=head2 status

Information specific to the runtime.

While this API specification does not define data provided by runtimes, the
following well-known properties may be provided by runtimes:

C<org.opencontainers.runtime-spec.features>: features structure as defined
in the L<OCI Runtime
Specification|https://github.com/opencontainers/runtime-spec/blob/main/features.md>,
in a JSON string representation.

> B<Note>: The information returned in this field, including the >
formatting of values and labels, should not be considered stable, > and may
change without notice. B<The keys are the caller's data> and are never
translated. Serialised as C<status> -- spelled out, because deriving it from
the Perl name would produce C<Status>.

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

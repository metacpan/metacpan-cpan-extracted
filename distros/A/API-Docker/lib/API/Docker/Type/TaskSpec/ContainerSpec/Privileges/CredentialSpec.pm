package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec;
# ABSTRACT: CredentialSpec for managed service account (Windows only)
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker config => Str;


docker file => Str;


docker registry => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec - CredentialSpec for managed service account (Windows only)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<CredentialSpec> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=head2 config

Load credential spec from a Swarm Config with the given ID. The specified
config must also be present in the Configs field with the Runtime property
set.

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

=head2 file

Load credential spec from this file. The file is read by the daemon, and
must be present in the C<CredentialSpecs> subdirectory in the docker data
directory, which defaults to C<C:\ProgramData\Docker\> on Windows.

For example, specifying C<spec.json> loads
C<C:\ProgramData\Docker\CredentialSpecs\spec.json>.

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

=head2 registry

Load credential spec from this value in the Windows registry. The specified
registry value must be located in:

C<HKLM\SOFTWARE\Microsoft\Windows
NT\CurrentVersion\Virtualization\Containers\CredentialSpecs>

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

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

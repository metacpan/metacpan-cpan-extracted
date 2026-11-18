package API::Docker::Type::TaskSpec::ContainerSpec::Privileges;
# ABSTRACT: Security options for the container
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::Seccomp;
use namespace::clean;


docker credential_spec => 'TaskSpec::ContainerSpec::Privileges::CredentialSpec',
  ;


docker selinux_context => 'TaskSpec::ContainerSpec::Privileges::SELinuxContext',
  wire => 'SELinuxContext';


docker seccomp => 'TaskSpec::ContainerSpec::Privileges::Seccomp',
  since => '1.44';


docker app_armor => 'TaskSpec::ContainerSpec::Privileges::AppArmor',
  since => '1.44';


docker no_new_privileges => Bool, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Privileges - Security options for the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Privileges> schema of C<TaskSpec.ContainerSpec>
in C<spec/v1.51.yaml>.

=head2 credential_spec

CredentialSpec for managed service account (Windows only). See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec>.

=head2 selinux_context

SELinux labels of the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext>.
Serialised as C<SELinuxContext> -- spelled out, because deriving it from the
Perl name would produce C<SelinuxContext>.

=head2 seccomp

Options for configuring seccomp on the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::Seccomp>.

=head2 app_armor

Options for configuring AppArmor on the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor>.

=head2 no_new_privileges

Configuration of the no_new_privs bit in the container.

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

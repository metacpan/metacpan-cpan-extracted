package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor;
# ABSTRACT: Options for configuring AppArmor on the container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker mode => Str, since => '1.44', enum => [qw( default disabled )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor - Options for configuring AppArmor on the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<AppArmor> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=head2 mode

Undocumented upstream. The whole of what this object configures: AppArmor
left at the engine's default, or turned off. The swagger enumerates
C<default> and C<disabled>.

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

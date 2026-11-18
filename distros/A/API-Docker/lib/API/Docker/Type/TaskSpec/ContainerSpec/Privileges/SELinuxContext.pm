package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext;
# ABSTRACT: SELinux labels of the container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker disable => Bool;


docker user => Str;


docker role => Str;


docker type => Str;


docker level => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext - SELinux labels of the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<SELinuxContext> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=head2 disable

Disable SELinux.

=head2 user

SELinux user label.

=head2 role

SELinux role label.

=head2 type

SELinux type label.

=head2 level

SELinux level label.

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

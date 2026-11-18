package API::Docker::Type::ContainerSummary::HostConfig;
# ABSTRACT: Summary of host-specific runtime information of the container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker network_mode => Str;


docker annotations => { Str, Str }, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerSummary::HostConfig - Summary of host-specific runtime information of the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<HostConfig> schema of the C<ContainerSummary>
definition in C<spec/v1.51.yaml>.

This is a reduced set of information in the container's "HostConfig" as
available in the container "inspect" response.

=head2 network_mode

Networking mode (C<host>, C<none>, C<< container:<id> >>) or name of the
primary network the container is using.

This field is primarily for backward compatibility. The container can be
connected to multiple networks for which information can be found in the
C<NetworkSettings.Networks> field, which enumerates settings per network.

=head2 annotations

Arbitrary key-value metadata attached to the container. B<The keys are the
caller's data> and are never translated.

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

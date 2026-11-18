package API::Docker::Type::ContainerSummary::NetworkSettings;
# ABSTRACT: Summary of the container's network settings
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointSettings;
use namespace::clean;


docker networks => { Str, 'EndpointSettings' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerSummary::NetworkSettings - Summary of the container's network settings

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<NetworkSettings> schema of the
C<ContainerSummary> definition in C<spec/v1.51.yaml>.

=head2 networks

Summary of network-settings for each network the container is attached to.
See L<API::Docker::Type::EndpointSettings>. B<The keys are the caller's
data> and are never translated.

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

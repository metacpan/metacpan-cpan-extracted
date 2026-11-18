package API::Docker::Type::NetworkAttachmentConfig;
# ABSTRACT: Specifies how a service should be attached to a particular network
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker target => Str;


docker aliases => [Str];


docker driver_opts => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NetworkAttachmentConfig - Specifies how a service should be attached to a particular network

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NetworkAttachmentConfig> definition of
C<spec/v1.51.yaml>.

=head2 target

The target network for attachment. Must be a network name or ID.

=head2 aliases

Discoverable alternate names for the service on this network.

=head2 driver_opts

Driver attachment options for the network target. B<The keys are the
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

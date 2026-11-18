package API::Docker::Type::ConfigReference;
# ABSTRACT: The config-only network source to provide the configuration for this network
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker network => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ConfigReference - The config-only network source to provide the configuration for this network

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ConfigReference> definition of C<spec/v1.51.yaml>.

=head2 network

The name of the config-only network that provides the network's
configuration. The specified network must be an existing config-only
network. Only network names are allowed, not network IDs.

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

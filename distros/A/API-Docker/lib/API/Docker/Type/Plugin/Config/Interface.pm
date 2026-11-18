package API::Docker::Type::Plugin::Config::Interface;
# ABSTRACT: The interface between Docker and the plugin
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::PluginInterfaceType;
use namespace::clean;


docker types => [ 'PluginInterfaceType' ];


docker socket => Str;


docker protocol_scheme => Str, enum => [ '', 'moby.plugins.http/v1' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config::Interface - The interface between Docker and the plugin

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Interface> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>.

=head2 types

Undocumented upstream. The plugin API contracts the plugin implements. The
swagger's example is the bare string C<docker.volumedriver/1.0> even though
the items are objects, and its three parts line up with the C<Prefix>,
C<Capability> and C<Version> of the class each item actually is, in that
order. See L<API::Docker::Type::PluginInterfaceType>.

=head2 socket

Undocumented upstream. The socket the engine reaches the plugin over,
C<plugins.sock> in the swagger's example -- a name, not a path.

=head2 protocol_scheme

Protocol to use for clients connecting to the plugin. The swagger enumerates
the empty string and C<moby.plugins.http/v1>.

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

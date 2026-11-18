package API::Docker::Type::Plugin;
# ABSTRACT: A plugin for the Engine API
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Plugin::Config;
use API::Docker::Type::Plugin::Settings;
use namespace::clean;


docker id => Str;


docker name => Str, required => 1;


docker enabled => Bool, required => 1;


docker settings => 'Plugin::Settings', required => 1;


docker plugin_reference => Str;


docker config => 'Plugin::Config', required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin - A plugin for the Engine API

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Plugin> definition of C<spec/v1.51.yaml>. Nothing in
this class or in the ones hanging off it is backed by a measurement.
Rootless Podman serves no plugin route at all, so on the engine this
distribution measures against there is nothing here to observe; see
L<API::Docker::API::Plugins/"Not available on Podman">. Everything below is
read off the swagger's own examples.

=head2 id

Undocumented upstream. The plugin's own ID, a 64-character hex digest in the
swagger's example. The C</plugins/{name}/...> endpoints address a plugin by
L</name>, not by this.

=head2 name

Undocumented upstream. The plugin's reference,
C<tiborvass/sample-volume-plugin> in the swagger's example, and what the
C</plugins/{name}/...> endpoints take in their path -- where the swagger
notes the C<:latest> tag is optional and the default when omitted.
L</plugin_reference> is the full remote reference the plugin was pushed or
pulled under. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 enabled

True if the plugin is running. False if the plugin is not running, only
installed. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=head2 settings

Settings that can be modified by users. See
L<API::Docker::Type::Plugin::Settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 plugin_reference

Plugin remote reference used to push/pull the plugin.

=head2 config

The config of a plugin. See L<API::Docker::Type::Plugin::Config>. The
swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

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

package API::Docker::Type::Plugin::Config;
# ABSTRACT: The config of a plugin
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Plugin::Config::Args;
use API::Docker::Type::Plugin::Config::Interface;
use API::Docker::Type::Plugin::Config::Linux;
use API::Docker::Type::Plugin::Config::Network;
use API::Docker::Type::Plugin::Config::RootFS;
use API::Docker::Type::Plugin::Config::User;
use API::Docker::Type::PluginEnv;
use API::Docker::Type::PluginMount;
use namespace::clean;


docker docker_version => Str;


docker description => Str;


docker documentation => Str;


docker interface => 'Plugin::Config::Interface';


docker entrypoint => [Str];


docker work_dir => Str;


docker user => 'Plugin::Config::User';


docker network => 'Plugin::Config::Network';


docker linux => 'Plugin::Config::Linux';


docker propagated_mount => Str;


docker ipc_host => Bool;


docker pid_host => Bool;


docker mounts => [ 'PluginMount' ];


docker env => [ 'PluginEnv' ];


docker args => 'Plugin::Config::Args';


docker rootfs => 'Plugin::Config::RootFS', wire => 'rootfs';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config - The config of a plugin

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Config> schema of the C<Plugin> definition in
C<spec/v1.51.yaml>.

=head2 docker_version

Docker Version used to create the plugin.

Depending on how the plugin was created, this field may be empty or omitted.

Deprecated: this field is no longer set, and will be removed in the next API
version.

=head2 description

Undocumented upstream. The plugin's own one-line description, C<"A sample
volume plugin for Docker"> in the swagger's example.

=head2 documentation

Undocumented upstream. A URL,
C<https://docs.docker.com/engine/extend/plugins/> in the swagger's example.

=head2 interface

The interface between Docker and the plugin. See
L<API::Docker::Type::Plugin::Config::Interface>.

=head2 entrypoint

Undocumented upstream. The command the plugin's process is started with, one
string per argument: C<< ["/usr/bin/sample-volume-plugin", "/data"] >> in
the swagger's example.

=head2 work_dir

Undocumented upstream. The working directory that process starts in,
C<"/bin/"> in the swagger's example.

=head2 user

Undocumented upstream. Two C<uint32>s, both C<1000> in the swagger's
example. See L<API::Docker::Type::Plugin::Config::User>.

=head2 network

Undocumented upstream. One field, a network mode; C<host> in the swagger's
example. See L<API::Docker::Type::Plugin::Config::Network>.

=head2 linux

Undocumented upstream. The Linux capabilities the plugin needs, whether it
may use every device, and the devices it declares by hand. See
L<API::Docker::Type::Plugin::Config::Linux>.

=head2 propagated_mount

Undocumented upstream. A path, C<"/mnt/volumes"> in the swagger's example.
That example is all the swagger offers about it.

=head2 ipc_host

Undocumented upstream.

=head2 pid_host

Undocumented upstream.

=head2 mounts

Undocumented upstream. The mounts the plugin declares.
L<API::Docker::Type::Plugin/settings> carries the same list as it stands
after a user has changed it. See L<API::Docker::Type::PluginMount>.

=head2 env

Undocumented upstream. The environment variables the plugin declares, each
an object with its own description and value: the swagger's example is a
single C<DEBUG>, "if set, prints debug messages", currently C<"0">.
L<API::Docker::Type::Plugin::Settings/env> carries the same variables as
bare C<NAME=value> strings. See L<API::Docker::Type::PluginEnv>.

=head2 args

Undocumented upstream. The plugin's command line as one named item --
C<args>, "command line arguments", in the swagger's example -- not one item
per argument. See L<API::Docker::Type::Plugin::Config::Args>.

=head2 rootfs

Undocumented upstream. A type and a list of layer digests, both spelled in
lower case upstream. See L<API::Docker::Type::Plugin::Config::RootFS>.
Serialised as C<rootfs> -- spelled out, because deriving it from the Perl
name would produce C<Rootfs>.

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

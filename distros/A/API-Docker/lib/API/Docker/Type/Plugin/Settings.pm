package API::Docker::Type::Plugin::Settings;
# ABSTRACT: Settings that can be modified by users
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;
use API::Docker::Type::PluginMount;
use namespace::clean;


docker mounts => [ 'PluginMount' ];


docker env => [Str];


docker args => [Str];


docker devices => [ 'PluginDevice' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Settings - Settings that can be modified by users

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Settings> schema of the C<Plugin> definition in
C<spec/v1.51.yaml>.

=head2 mounts

Undocumented upstream. The plugin's mounts as they now stand;
L<API::Docker::Type::Plugin::Config/mounts> is the same list as the plugin
declared it. See L<API::Docker::Type::PluginMount>.

=head2 env

Undocumented upstream. The environment as bare C<NAME=value> strings, C<<
["DEBUG=0"] >> in the swagger's example -- the shape C<POST
/plugins/{name}/set> takes in its body, whose own example is C<< ["DEBUG=1"]
>>. L<API::Docker::Type::Plugin::Config/env> carries the same variables as
objects with their descriptions.

=head2 args

Undocumented upstream. The command line as bare strings, against the single
named item L<API::Docker::Type::Plugin::Config/args> declares.

=head2 devices

Undocumented upstream. The plugin's devices as they now stand;
L<API::Docker::Type::Plugin::Config::Linux/devices> is the declared list.
See L<API::Docker::Type::PluginDevice>.

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

package API::Docker::Type::TaskSpec::PluginSpec;
# ABSTRACT: Plugin spec for the service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::PluginPrivilege;
use namespace::clean;


docker name => Str;


docker remote => Str;


docker disabled => Bool;


docker plugin_privilege => [ 'PluginPrivilege' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::PluginSpec - Plugin spec for the service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<PluginSpec> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

*(Experimental release only.)*

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=head2 name

The name or 'alias' to use for the plugin.

=head2 remote

The plugin image reference to use.

=head2 disabled

Disable the plugin once scheduled.

=head2 plugin_privilege

Undocumented upstream. The permissions installing the plugin requires the
user to accept, one entry per permission. The other three fields of this
spec -- C<Name>, C<Remote> and C<Disabled> -- are described upstream; this
one is not. See L<API::Docker::Type::PluginPrivilege>.

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

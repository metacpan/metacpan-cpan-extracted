package API::Docker::Type::PluginMount;
# ABSTRACT: One entry of C<Plugin.Config.Mounts>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str, required => 1;


docker description => Str, required => 1;


docker settable => [Str], required => 1;


docker source => Str, required => 1;


docker destination => Str, required => 1;


docker type => Str, required => 1;


docker options => [Str], required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PluginMount - One entry of C<Plugin.Config.Mounts>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PluginMount> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Plugin.Config.Mounts> and C<Plugin.Settings.Mounts>.

=head2 name

Undocumented upstream. C<"some-mount"> in the swagger's example. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 description

Undocumented upstream. C<"This is a mount that's used by the plugin."> in
the swagger's example. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 settable

Undocumented upstream. An array of strings, and the swagger never says what
they hold. What a user changes on an installed plugin goes in through C<POST
/plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 source

Undocumented upstream. Where the mount comes from on the host,
C<"/var/lib/docker/plugins/"> in the swagger's example -- what
L<API::Docker::Type::Mount/source> is for a container. The swagger lists
this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 destination

Undocumented upstream. Where it appears inside the plugin, C<"/mnt/state">
in the swagger's example -- what L<API::Docker::Type::Mount/target> is for a
container. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=head2 type

Undocumented upstream. C<"bind"> in the swagger's example. The
container-side field this mirrors, L<API::Docker::Type::Mount/type>, is an
enumeration the swagger describes value by value; this one is a bare string.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=head2 options

Undocumented upstream. Mount options, one string each: C<< ["rbind", "rw"]
>> in the swagger's example. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

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

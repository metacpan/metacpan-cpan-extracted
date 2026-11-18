package API::Docker::Type::PluginDevice;
# ABSTRACT: One entry of C<Plugin.Config.Linux.Devices>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str, required => 1;


docker description => Str, required => 1;


docker settable => [Str], required => 1;


docker path => Str, required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PluginDevice - One entry of C<Plugin.Config.Linux.Devices>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PluginDevice> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Plugin.Config.Linux.Devices> and
C<Plugin.Settings.Devices>.

=head2 name

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 description

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 settable

Undocumented upstream. An array of strings, and the swagger never says what
they hold. What a user changes on an installed plugin goes in through C<POST
/plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 path

Undocumented upstream. The device node, C<"/dev/fuse"> in the swagger's
example. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

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
